# frozen_string_literal: true

class Song < ActiveRecord::Base
  has_many :artists_songs
  has_many :artists, through: :artists_songs
  has_many :generalplaylists
  has_many :radiostations, through: :generalplaylists

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
    songs
  end

  def self.group_and_count(songs)
    songs.group(:song_id).count.sort_by { |_song_id, counter| counter }.reverse
  end

  def set_song_artists
    # find all possible tracks on spotify
    tracks = RSpotify::Track.search("#{artists.map { |artist| artist.name.gsub(/;|feat.|ft.|feat|ft|&|vs.|vs|versus|and/, '') }.join(' ')} #{title}").sort_by(&:popularity).reverse
    # filter all tracks that only have th artist name
    tracks = tracks.filter do |t|
      # e.g. ['martin, 'garrix', 'clinton', 'kane']
      track_artists_names = t.artists.map { |artist| artist.name.downcase.split(' ') }
      song_artists_names = artists.map do |artist|
        if artist.name.match?(/;|feat.|ft.|feat|ft|&|vs.|vs|versus|and/)
          artist.name.gsub(/;|feat.|ft.|feat|ft|&|vs.|vs|versus|and/, '').downcase.split(' ')
        else
          artist.name.downcase.split(' ')
        end
      end

      # compare artists from track and artists from song. If they match the difference array wil be empty and return true
      same_artists = (track_artists_names.flatten - song_artists_names.flatten).empty?
      same_artists && track_artists_names.exclude?('karaoke')
    end
    # set the trackt to first
    track = tracks.first
    # replace track with most popular track
    tracks.each do |t|
      track = t if t.popularity > track.popularity
    end

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

    update!(spotify_song_url: track.external_urls['spotify'], spotify_artwork_url: track.album.images[1]['url'])
  end
end
