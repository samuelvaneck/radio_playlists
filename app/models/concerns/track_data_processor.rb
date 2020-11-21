# frozen_string_literal: true

module TrackDataProcessor
  extend ActiveSupport::Concern

  module ClassMethods
    def process_track_data(artist_name, title)
      artists = find_or_create_artist(artist_name, title)
      songs = Song.where('lower(title) = ?', title.downcase)
      song = song_check(songs, artists, title)
      [artists, song]
    end

    def find_or_create_artist(name, song_title)
      search_term = if name.match?(/;|feat.|ft.|feat|ft|&|vs.|vs|versus|and/)
                      name.gsub(/;|feat.|ft.|feat|ft|&|vs.|vs|versus|and/, '').downcase.split(' ')
                    else
                      name.downcase.split(' ')
                    end

      # getting spotify track / filter out the aritst / get the track that is most popular
      tracks = RSpotify::Track.search("#{search_term.join(' ')} #{song_title}").sort_by(&:popularity).reverse

      # filter tracks
      filter_array = ['karoke', 'cover', 'made famous', 'tribute', 'backing business', 'arcade', 'instrumental', '8-bit', '16-bit']
      filtered_tracks = []
      tracks.each do |track|
        next if filter_array.include? track.artists.map(&:name).join(' ').downcase

        filtered_tracks << track
      end

      # get most popular track
      track = filtered_tracks.max_by(&:popularity)

      if track.present?
        track.artists.map do |track_artist|
          artist = Artist.find_or_initialize_by(name: track_artist.name)
          # sanitizing artist
          spotify_artist = artist.spotify_search(artist.name)
          artist.name = spotify_artist.name
          # set Spotify links
          artist.spotify_artist_url = spotify_artist.external_urls['spotify']
          artist.spotify_artwork_url = spotify_artist.images.first['url']
          artist.save

          artist
        end
      else
        Artist.find_or_initialize_by(name: name)
      end
    end

    # Methode for checking if there are songs with the same title.
    # if so the artist id must be check
    # if the artist with the some song is not in the database the song with artist Id must be added
    def song_check(songs, artists, title)
      # If there is no song with the same title create a new one
      result = nil
      if songs.blank?
        result = Song.find_or_create_by(title: title)
      # If the is a song with the same title check the artist
      elsif artists.blank?
        # If there is no song title with the same artist create a new one
        result = Song.find_or_create_by(title: title)
      else
        # Else grap the song record with the same title and artist id
        artist_ids = Array.wrap(artists.map(&:id))
        query_songs = Song.joins(:artists).where(artists: { id: artist_ids }, title: title)
        if query_songs.present?
          result = query_songs
        else
          song = Song.new(title: title)
          song.artists << artists
          result = song
        end
      end

      song = result.is_a?(Song) ? result : result.first
      # set spotify song links
      find_spotify_links(song, artists)
      song
    end

    def find_spotify_links(song, artists)
      spotify_song = song.spotify_search(artists)
      if spotify_song.present?
        song.title = spotify_song.name
        song.spotify_song_url = spotify_song.external_urls['spotify']
        song.spotify_artwork_url = spotify_song.album.images[0]['url']
        song.save
      end
    end

    def illegal_word_in_title(title)
      # catch more then 4 digits, forward slashes, 2 single qoutes,
      # reklame/reclame/nieuws/pingel and 2 dots
      if title.match(/\d{4,}|\/|'{2,}|(reklame|reclame|nieuws|pingel)|\.{2,}/i)
        Rails.logger.info "Find illegal word in #{title}"
        true
      else
        false
      end
    end
  end
end
