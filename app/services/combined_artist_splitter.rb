# frozen_string_literal: true

class CombinedArtistSplitter
  attr_reader :combined_artist, :individual_artists

  def initialize(combined_artist)
    @combined_artist = combined_artist
    @individual_artists = []
  end

  def split
    artist_names = extract_artist_names
    raise ArgumentError, "Could not split '#{combined_artist.name}' into multiple artists" if artist_names.size < 2

    @individual_artists = find_or_create_artists(artist_names)

    ActiveRecord::Base.transaction do
      reassign_songs
      reassign_chart_positions
      combined_artist.reload.destroy!
    end

    @individual_artists
  end

  private

  def extract_artist_names
    regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
    combined_artist.name.split(regex).map(&:strip).reject(&:blank?)
  end

  def find_or_create_artists(names)
    names.map do |name|
      Artist.find_or_create_by!(name:)
    end
  end

  def reassign_songs
    song_ids = combined_artist.artists_songs.pluck(:song_id)
    valid_song_ids = Song.where(id: song_ids).pluck(:id)

    ArtistsSong.where(artist_id: combined_artist.id).delete_all

    individual_artists.each do |artist|
      existing_song_ids = ArtistsSong.where(artist_id: artist.id, song_id: valid_song_ids).pluck(:song_id)
      (valid_song_ids - existing_song_ids).each do |song_id|
        ArtistsSong.create!(artist_id: artist.id, song_id:)
      end
    end
  end

  def reassign_chart_positions
    combined_artist.chart_positions.each do |cp|
      individual_artists.each do |artist|
        existing = ChartPosition.find_by(positianable: artist, chart_id: cp.chart_id)
        next if existing

        cp.update!(positianable: artist)
        break
      end
    end

    # Delete any remaining chart positions still on the combined artist
    combined_artist.chart_positions.reload.destroy_all
  end
end
