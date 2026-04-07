# frozen_string_literal: true

# Finds and fixes songs whose isrcs array contains ISRCs from different recordings.
# This happens when two different songs sharing an artist get incorrectly linked,
# and ISRCs from one song "leak" into the other via build_spotify_updates.
#
# Detection: For each ISRC on a song, look up the Spotify track by ISRC. If the
# Spotify track ID differs from the song's id_on_spotify, that ISRC doesn't belong.
#
# Fix: Remove the foreign ISRCs from the song's isrcs array.
class IsrcCrossContaminationRepair
  attr_reader :results

  def initialize(dry_run: true, limit: 500)
    @dry_run = dry_run
    @limit = limit
    @results = { checked: 0, contaminated: 0, fixed: 0, errors: [] }
  end

  def run
    contaminated_songs.find_each do |song|
      @results[:checked] += 1
      process_song(song)
    end

    @results
  end

  private

  def contaminated_songs
    Song.where.not(id_on_spotify: nil)
      .where('array_length(isrcs, 1) > 1')
      .order(updated_at: :desc)
      .limit(@limit)
  end

  def process_song(song)
    foreign_isrcs = find_foreign_isrcs(song)
    return if foreign_isrcs.blank?

    @results[:contaminated] += 1
    report_contamination(song, foreign_isrcs)

    return if @dry_run

    clean_isrcs = song.isrcs - foreign_isrcs
    song.update!(isrcs: clean_isrcs)
    @results[:fixed] += 1
  rescue StandardError => e
    @results[:errors] << { song_id: song.id, error: e.message }
  end

  def find_foreign_isrcs(song)
    song.isrcs.select do |isrc|
      other_song = Song.where('? = ANY(isrcs)', isrc)
                     .where.not(id: song.id)
                     .where.not(id_on_spotify: [nil, song.id_on_spotify])
                     .first
      next false if other_song.blank?

      # This ISRC also appears on a different song with a different Spotify ID
      $stdout.puts "  ISRC #{isrc} also on song ##{other_song.id} " \
                   "(#{other_song.title} - spotify:#{other_song.id_on_spotify})"
      true
    end
  end

  def report_contamination(song, foreign_isrcs)
    $stdout.puts "\nSong ##{song.id}: #{song.title}"
    $stdout.puts "  Spotify ID: #{song.id_on_spotify}"
    $stdout.puts "  Current ISRCs: #{song.isrcs.inspect}"
    $stdout.puts "  Foreign ISRCs: #{foreign_isrcs.inspect}"
    $stdout.puts "  Action: #{@dry_run ? 'WOULD REMOVE' : 'REMOVING'} foreign ISRCs"
  end
end
