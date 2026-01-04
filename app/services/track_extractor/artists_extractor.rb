# frozen_string_literal: true

class TrackExtractor::ArtistsExtractor < TrackExtractor
  def extract
    find_or_create_artist
  end

  private

  def find_or_create_artist
    if @track.present? && @track.artists.present?
      track_to_artist
    else
      Artist.find_or_initialize_by(name: artist_name)
    end
  rescue StandardError => e
    ExceptionNotifier.notify_new_relic(e)
    nil
  end

  def track_to_artist
    if spotify_track?
      Artist.spotify_track_to_artist(@track)
    else
      non_spotify_track_to_artist
    end
  end

  def spotify_track?
    @track.respond_to?(:spotify_song_url) && @track.spotify_song_url.present?
  end

  def non_spotify_track_to_artist
    @track.artists.map do |track_artist|
      artist = Artist.find_or_initialize_by(name: track_artist['name'])
      artist.save if artist.new_record?
      artist
    end
  end
end
