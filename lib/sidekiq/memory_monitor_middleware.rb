# frozen_string_literal: true

require 'objspace'

module Sidekiq
  class MemoryMonitorMiddleware
    # Sidekiq server middleware that tracks memory usage per job.
    #
    # What it does:
    # 1. Measures RSS before/after every job — logs jobs that grow memory by >= GROWTH_THRESHOLD_MB
    # 2. Every STATS_INTERVAL jobs, logs GC stats and top retained object classes
    # 3. Tracks cumulative RSS growth since Sidekiq boot to detect slow leaks
    #
    # Usage: added automatically via config/initializers/sidekiq.rb
    # Disable: set SIDEKIQ_MEMORY_MONITOR=false env var

    GROWTH_THRESHOLD_MB = ENV.fetch('MEMORY_GROWTH_THRESHOLD_MB', 5).to_f.freeze
    STATS_INTERVAL = ENV.fetch('MEMORY_STATS_INTERVAL', 100).to_i.freeze
    TOP_CLASSES_COUNT = 20

    def initialize
      @job_count = 0
      @boot_rss = current_rss_mb
      @cumulative_growth = {}
      @mutex = Mutex.new
    end

    def call(_worker, job, _queue)
      return yield unless enabled?

      rss_before = current_rss_mb
      gc_stat_before = GC.stat(:total_freed_objects)

      yield

      rss_after = current_rss_mb
      gc_freed = GC.stat(:total_freed_objects) - gc_stat_before
      growth = rss_after - rss_before
      job_class = job['class']

      track_growth(job_class, growth)
      log_job_growth(job_class, rss_before, rss_after, growth, gc_freed) if growth >= GROWTH_THRESHOLD_MB

      @mutex.synchronize { @job_count += 1 }
      log_periodic_stats(rss_after) if (@job_count % STATS_INTERVAL).zero?
    end

    private

    def enabled?
      ENV.fetch('SIDEKIQ_MEMORY_MONITOR', 'true') != 'false'
    end

    def current_rss_mb
      # /proc/self/status is fastest on Linux; fall back to ps on macOS
      if File.exist?('/proc/self/status')
        File.read('/proc/self/status').match(/VmRSS:\s+(\d+)/)[1].to_f / 1024.0
      else
        `ps -o rss= -p #{Process.pid}`.strip.to_f / 1024.0
      end
    rescue StandardError
      0.0
    end

    def track_growth(job_class, growth)
      @mutex.synchronize do
        @cumulative_growth[job_class] ||= { total_mb: 0.0, runs: 0, max_growth: 0.0 }
        entry = @cumulative_growth[job_class]
        entry[:total_mb] += growth
        entry[:runs] += 1
        entry[:max_growth] = [entry[:max_growth], growth].max
      end
    end

    def log_job_growth(job_class, rss_before, rss_after, growth, gc_freed)
      Rails.logger.warn(
        "[MemoryMonitor] Job #{job_class} grew #{format('%.1f', growth)}MB " \
        "(#{format('%.1f', rss_before)} -> #{format('%.1f', rss_after)}MB RSS, " \
        "GC freed: #{gc_freed} objects)"
      )
    end

    def log_periodic_stats(current_rss)
      total_growth = current_rss - @boot_rss

      lines = []
      lines << "[MemoryMonitor] === Periodic Stats (after #{@job_count} jobs) ==="
      lines << "[MemoryMonitor] RSS: #{format('%.1f', current_rss)}MB (#{format('%+.1f', total_growth)}MB since boot)"
      lines << "[MemoryMonitor] GC stats: #{gc_summary}"
      lines << "[MemoryMonitor] Top object classes: #{top_object_classes}"
      lines << '[MemoryMonitor] Per-job growth:'

      leaky_jobs = @mutex.synchronize do
        @cumulative_growth
          .sort_by { |_, v| -v[:total_mb] }
          .first(10)
      end

      leaky_jobs.each do |job_class, stats|
        avg = stats[:runs].positive? ? stats[:total_mb] / stats[:runs] : 0
        lines << "[MemoryMonitor]   #{job_class}: #{format('%.1f', stats[:total_mb])}MB total " \
                 "(#{stats[:runs]} runs, avg #{format('%.2f', avg)}MB, max #{format('%.1f', stats[:max_growth])}MB)"
      end

      Rails.logger.warn(lines.join("\n"))
    end

    def gc_summary
      stat = GC.stat
      "count=#{stat[:count]} heap_live=#{stat[:heap_live_slots]} " \
        "heap_free=#{stat[:heap_free_slots]} old_objects=#{stat[:old_objects]} " \
        "malloc_increase=#{stat[:malloc_increase_bytes]}B"
    end

    def top_object_classes
      class_of = Kernel.instance_method(:class)
      counts = Hash.new(0)
      ObjectSpace.each_object { |obj| counts[class_of.bind_call(obj)] += 1 }
      counts
        .sort_by { |_, c| -c }
        .first(TOP_CLASSES_COUNT)
        .map { |klass, count| "#{klass}=#{count}" }
        .join(', ')
    rescue StandardError => e
      "error: #{e.message}"
    end
  end
end
