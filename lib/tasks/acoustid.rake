# frozen_string_literal: true

namespace :acoustid do
  desc 'Enqueue songs with YouTube IDs for AcoustID fingerprint submission'
  task populate: :environment do
    puts 'Enqueuing songs for AcoustID population...'

    pending_count = Song.where(acoustid_submitted_at: nil)
                        .where.not(id_on_youtube: nil)
                        .count

    puts "Found #{pending_count} songs with YouTube IDs pending submission"

    if pending_count.zero?
      puts 'No songs to process.'
      return
    end

    count = AcoustidPopulationJob.enqueue_all
    puts "Enqueued #{count} jobs. Check Sidekiq for progress."
  end

  desc 'Enqueue a limited batch of songs for AcoustID submission. Usage: rake acoustid:populate_batch[100]'
  task :populate_batch, [:limit] => :environment do |_t, args|
    limit = args[:limit]&.to_i || 100
    puts "Enqueuing up to #{limit} songs for AcoustID population..."

    count = AcoustidPopulationJob.enqueue_all(limit: limit)
    puts "Enqueued #{count} jobs. Check Sidekiq for progress."
  end

  desc 'Show AcoustID population statistics'
  task stats: :environment do
    total_songs = Song.count
    with_youtube = Song.where.not(id_on_youtube: nil).count
    submitted = Song.where.not(acoustid_submitted_at: nil).count
    pending = Song.where(acoustid_submitted_at: nil).where.not(id_on_youtube: nil).count

    puts 'AcoustID Population Statistics'
    puts '=' * 40
    puts "Total songs:              #{total_songs}"
    puts "Songs with YouTube ID:    #{with_youtube}"
    puts "Already submitted:        #{submitted}"
    puts "Pending submission:       #{pending}"
    puts
    puts "Completion: #{((submitted.to_f / with_youtube) * 100).round(1)}%" if with_youtube.positive?
  end

  desc 'Process a single song for AcoustID submission. Usage: rake acoustid:submit_one[123]'
  task :submit_one, [:song_id] => :environment do |_t, args|
    song_id = args[:song_id]
    abort 'Please provide a song ID: rake acoustid:submit_one[123]' if song_id.blank?

    song = Song.find_by(id: song_id)
    abort "Song with ID #{song_id} not found" if song.blank?
    abort 'Song does not have a YouTube ID' if song.id_on_youtube.blank?

    puts "Processing song: #{song.title} (ID: #{song.id})"
    puts "YouTube ID: #{song.id_on_youtube}"

    AcoustidPopulationJob.new.perform(song.id)

    song.reload
    if song.acoustid_submitted_at.present?
      puts "Successfully submitted at #{song.acoustid_submitted_at}"
    else
      puts 'Submission may have failed. Check logs for details.'
    end
  end

  desc 'Reset submission status for a song. Usage: rake acoustid:reset[123]'
  task :reset, [:song_id] => :environment do |_t, args|
    song_id = args[:song_id]
    abort 'Please provide a song ID: rake acoustid:reset[123]' if song_id.blank?

    song = Song.find_by(id: song_id)
    abort "Song with ID #{song_id} not found" if song.blank?

    song.update!(acoustid_submitted_at: nil)
    puts "Reset acoustid_submitted_at for song #{song.id} (#{song.title})"
  end
end
