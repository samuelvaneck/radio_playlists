# frozen_string_literal: true

namespace :persistent_streams do
  desc 'Start the persistent stream manager (long-lived, blocking process)'
  task start: :environment do
    puts 'Starting PersistentStream::Manager...'
    manager = PersistentStream::Manager.new
    manager.start
  end

  desc 'Show status of all persistent stream processes'
  task status: :environment do
    manager = PersistentStream::Manager.new

    stations = RadioStation.unscoped.where.not(direct_stream_url: [nil, ''])

    if stations.none?
      puts 'No radio stations with direct_stream_url configured.'
      return
    end

    puts 'Persistent Stream Status'
    puts '=' * 60

    stations.find_each do |station|
      reader = PersistentStream::SegmentReader.new(station)
      segment_dir = PersistentStream::SEGMENT_DIRECTORY.join(station.audio_file_name)

      state = if reader.available?
                'ACTIVE'
              elsif segment_dir.exist?
                'STALE'
              else
                'NOT RUNNING'
              end

      printf "%-25s %s\n", station.name, state
    end
  end
end
