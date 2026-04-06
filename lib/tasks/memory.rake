# frozen_string_literal: true

CLASS_OF = Kernel.instance_method(:class)

namespace :memory do
  desc 'Dump ObjectSpace heap to a JSON file for analysis (use with heapy gem or jq)'
  task heap_dump: :environment do
    require 'objspace'

    ObjectSpace.trace_object_allocations_start

    # Force a full GC to clean up garbage before dumping
    3.times { GC.start(full_mark: true, immediate_sweep: true) }

    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    filename = Rails.root.join("tmp/heap_dump_#{timestamp}.json")

    $stdout.puts "Dumping heap to #{filename}..."
    File.open(filename, 'w') { |f| ObjectSpace.dump_all(output: f) }
    $stdout.puts "Done. File size: #{(File.size(filename) / 1024.0 / 1024.0).round(1)}MB"
    $stdout.puts ''
    $stdout.puts 'Analyze with:'
    $stdout.puts "  cat #{filename} | ruby -rjson -e '"
    $stdout.puts '    counts = Hash.new(0)'
    $stdout.puts '    ARGF.each_line { |l| j = JSON.parse(l); counts[j["type"]] += 1 }'
    $stdout.puts %(    counts.sort_by { |_,v| -v }.each { |k,v| puts "#{k}: #{v}" })
    $stdout.puts "  '"
    $stdout.puts ''
    $stdout.puts "  Or install heapy: gem install heapy && heapy read #{filename}"
  end

  desc 'Show current process memory stats and top object classes'
  task stats: :environment do
    require 'objspace'

    3.times { GC.start(full_mark: true, immediate_sweep: true) }

    rss = if File.exist?('/proc/self/status')
            File.read('/proc/self/status').match(/VmRSS:\s+(\d+)/)[1].to_f / 1024.0
          else
            `ps -o rss= -p #{Process.pid}`.strip.to_f / 1024.0
          end

    $stdout.puts "=== Memory Stats (PID: #{Process.pid}) ==="
    $stdout.puts "RSS: #{format('%.1f', rss)}MB"
    $stdout.puts "ObjectSpace.memsize_of_all: #{format('%.1f', ObjectSpace.memsize_of_all / 1024.0 / 1024.0)}MB"
    $stdout.puts ''

    gc = GC.stat
    $stdout.puts '=== GC Stats ==='
    $stdout.puts "GC count: #{gc[:count]} (minor: #{gc[:minor_gc_count]}, major: #{gc[:major_gc_count]})"
    $stdout.puts "Heap live slots: #{gc[:heap_live_slots]}"
    $stdout.puts "Heap free slots: #{gc[:heap_free_slots]}"
    $stdout.puts "Old objects: #{gc[:old_objects]}"
    $stdout.puts "Malloc increase: #{(gc[:malloc_increase_bytes] / 1024.0).round(1)}KB"
    $stdout.puts ''

    $stdout.puts '=== Top 30 Object Classes by Count ==='
    counts = Hash.new(0)
    ObjectSpace.each_object { |obj| counts[CLASS_OF.bind_call(obj)] += 1 }
    counts.sort_by { |_, c| -c }.first(30).each do |klass, count|
      $stdout.puts "  #{klass}: #{count}"
    end
    $stdout.puts ''

    $stdout.puts '=== Top 20 Object Classes by Memory ==='
    sizes = Hash.new(0)
    ObjectSpace.each_object do |obj|
      sizes[CLASS_OF.bind_call(obj)] += ObjectSpace.memsize_of(obj)
    rescue StandardError
      next
    end
    sizes.sort_by { |_, s| -s }.first(20).each do |klass, size|
      $stdout.puts "  #{klass}: #{format('%.1f', size / 1024.0 / 1024.0)}MB"
    end
  end

  desc 'Compare object counts before/after running N iterations of a job (e.g. memory:profile_job[ImportSongJob,10])'
  task :profile_job, %i[job_class iterations] => :environment do |_, args|
    require 'objspace'

    job_class = args[:job_class].constantize
    iterations = (args[:iterations] || 5).to_i

    $stdout.puts "Profiling #{args[:job_class]} over #{iterations} iterations..."
    $stdout.puts ''

    # Warm up and baseline
    3.times { GC.start(full_mark: true, immediate_sweep: true) }
    rss_before = `ps -o rss= -p #{Process.pid}`.strip.to_f / 1024.0

    before_counts = Hash.new(0)
    ObjectSpace.each_object { |obj| before_counts[CLASS_OF.bind_call(obj)] += 1 }

    before_gc = GC.stat(:count)

    # Run jobs — fetch a sample of radio stations if it's ImportSongJob
    iterations.times do |i|
      if job_class == ImportSongJob
        station = RadioStation.order('RANDOM()').first
        if station.nil?
          $stdout.puts '  No radio stations found in database. Run `rails db:seed` first.'
          next
        end
        $stdout.puts "  Iteration #{i + 1}/#{iterations}: #{station.name}"
        job_class.new.perform(station.id)
      else
        $stdout.puts "  Iteration #{i + 1}/#{iterations}"
        job_class.perform_now
      end
    end

    # Measure after
    3.times { GC.start(full_mark: true, immediate_sweep: true) }
    rss_after = `ps -o rss= -p #{Process.pid}`.strip.to_f / 1024.0

    after_counts = Hash.new(0)
    ObjectSpace.each_object { |obj| after_counts[CLASS_OF.bind_call(obj)] += 1 }

    after_gc = GC.stat(:count)

    $stdout.puts ''
    $stdout.puts '=== Results ==='
    $stdout.puts "RSS: #{format('%.1f', rss_before)}MB -> #{format('%.1f', rss_after)}MB (#{format('%+.1f', rss_after - rss_before)}MB)"
    $stdout.puts "GC runs during profiling: #{after_gc - before_gc}"
    $stdout.puts ''

    $stdout.puts '=== Object Count Changes (top 20 growing) ==='
    diffs = {}
    (before_counts.keys + after_counts.keys).uniq.each do |klass|
      diff = after_counts[klass] - before_counts[klass]
      diffs[klass] = { before: before_counts[klass], after: after_counts[klass], diff: diff }
    end

    diffs
      .sort_by { |_, v| -v[:diff] }
      .first(20)
      .each do |klass, v|
        next if v[:diff].zero?

        $stdout.puts "  #{klass}: #{v[:before]} -> #{v[:after]} (#{format('%+d', v[:diff])})"
      end
  end
end
