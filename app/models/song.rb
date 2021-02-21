# frozen_string_literal: true

class Song < ActiveRecord::Base
  has_many :artists_songs
  has_many :artists, through: :artists_songs
  has_many :generalplaylists
  has_many :radiostations, through: :generalplaylists

  MULTIPLE_ARTIST_REGEX = ';|\bfeat\.|\bvs\.|\bft\.|\bft\b|\bfeat\b|\bft\b|\s&\s|\bvs\b|\bversus|\band\b|\bmet\b|\b,|\ben\b|\/'
  TRACK_FILTERS = ['karoke', 'cover', 'made famous', 'tribute', 'backing business', 'arcade', 'instrumental', '8-bit', '16-bit'].freeze
  public_constant :MULTIPLE_ARTIST_REGEX
  public_constant :TRACK_FILTERS

  def self.search_title(title)
    where('title ILIKE ?', "%#{title}%")
  end

  def self.search(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time = params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    songs = Generalplaylist.joins(:song, :artists).all
    songs.where!('songs.title ILIKE ? OR artists.name ILIKE ?', "%#{params[:search_term]}%", "%#{params[:search_term]}%") if params[:search_term].present?
    songs.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    songs.where!('generalplaylists.created_at > ?', start_time)
    songs.where!('generalplaylists.created_at < ?', end_time)
    songs.distinct
  end

  def self.group_and_count(songs)
    songs.group(:song_id).count.sort_by { |_song_id, counter| counter }.reverse
  end

  def reload_artists(requested_artist = nil)
    track = spotify_search(Array.wrap(requested_artist) || artists)
    # do nothing if no track is present
    return false unless track.present?

    # remove all song artists
    artists.clear
    track.artists.each do |track_artist|
      artist = Artist.find_or_create_by(name: track_artist.name)
      # set Spotify links
      spotify_artist = RSpotify::Artist.find(track_artist.id)

      artist.spotify_artist_url = spotify_artist.external_urls['spotify']
      artist.spotify_artwork_url = spotify_artist.images.first['url']
      artist.save

      artists << artist
    end

    update!(
      spotify_song_url: track.external_urls['spotify'],
      spotify_artwork_url: track.album.images[1]['url'],
      fullname: "#{artists.map { |artist| artist.name.gsub(/;|feat.|ft.|feat|ft|&|vs.|vs|versus|and/, '') }.join(' ')} #{title}"
    )
  end

  def spotify_search(search_artists)
    search_artists, search_title = parse_search_terms(search_artists)
    tracks = RSpotify::Track.search("#{search_artists} #{search_title}").sort_by(&:popularity).reverse

    tracks = filter_tracks(tracks, search_artists)

    # return most popular track
    tracks.max_by(&:popularity)
  end

  # set correct search value for Spotify
  # E.g. 'Topic - Breaking Me Ft. A7s' returns [Topic A7s, Breaking Me]
  def parse_search_terms(search_artists)
    regex = Regexp.new(MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
    if title.match?(regex)
      [Array.wrap(search_artists).map { |artist| artist.name.gsub(regex, '') }.join(' ') + ' ' + title.split(regex)[1], title.split(regex)[0].strip]
    else
      [Array.wrap(search_artists).map { |artist| artist.name.gsub(regex, '') }.join(' '), title]
    end
  end

  # filter all tracks that only have th artist name
  # filter out compilation albums
  def filter_tracks(tracks, search_artists)
    regex = Regexp.new(MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
    single_album_tracks = tracks.reject { |t| t.album.album_type == 'compilation' }

    single_album_tracks.filter do |t|
      # e.g. ['martin, 'garrix', 'clinton', 'kane']
      track_artists_names = t.artists.map { |artist| artist.name.downcase.split(' ') }.flatten.reject { |n| n.match(/\W/) }
      song_artists_names = search_artists.gsub(regex, '').downcase.split(' ').flatten.reject { |n| n.match(/\W/) }

      # compare artists from track and artists from song. If they match the difference array wil be empty and return true
      same_artists = (track_artists_names.flatten - song_artists_names.flatten).empty?
      same_artists && track_artists_names.exclude?('karaoke')
    end
  end

  def cleanup
    destroy if generalplaylists.blank?
    artists.each(&:cleanup)
  end
end
