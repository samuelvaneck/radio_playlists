# frozen_string_literal: true

class Generalplaylist < ActiveRecord::Base
  belongs_to :song
  belongs_to :radiostation
  belongs_to :artist

  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def self.check_npo_radio(address)
    retries ||= 0
    uri = URI address

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
      request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      response = http.request(request)
      track = JSON.parse(response.body)['data'][0]
      artist = find_or_create_artist(track['artist'])
      title = track['title']
      time = Time.parse(track['startdatetime']).strftime('%H:%M')

      [artist, title, time]
    end
  rescue Net::ReadTimeout => _e
    sleep 1
    retry if (retries += 1) < 3
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
  rescue Net::OpenTimeout => _e
    sleep 1
    retry if (retries += 1) < 3
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
  rescue StandardError
    sleep 1
    retry if (retries += 1) < 3
  end

  def self.check_talpa_radio(address)
    retries ||= 0
    uri = URI address

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
      request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      response = http.request(request)
      track = JSON.parse(response.body)['data']['getStation']['playouts'][0]
      artist = find_or_create_artist(track['track']['artistName'])
      title = track['track']['title']
      time = Time.parse(track['broadcastDate']).in_time_zone('Amsterdam').strftime('%H:%M')

      [artist, title, time]
    end
  rescue Net::ReadTimeout => _e
    sleep 1
    retry if (retries += 1) < 3
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
  rescue Net::OpenTimeout => _e
    sleep 1
    retry if (retries += 1) < 3
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
  rescue StandardError
    sleep 1
    retry if (retries += 1) < 3
  end

  ###########
  ### NPO ###
  ###########

  def self.radio_1_check
    address = 'https://www.nporadio1.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 1')
    artist, title, time = check_npo_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  # Check Radio 2 song
  def self.radio_2_check
    address = 'https://www.nporadio2.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 2')
    artist, title, time = check_npo_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  def self.radio_3fm_check
    address = 'https://www.npo3fm.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 3FM')
    artist, title, time = check_npo_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  def self.radio_4_check
    address = 'https://www.nporadio4.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 4')
    artist, title, time = check_npo_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  def self.radio_5_check
    address = 'https://www.nporadio5.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 5')
    artist, title, time = check_npo_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  #############
  ### TALPA ###
  #############

  def self.sky_radio_check
    address = 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22sky-radio%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D'
    radio_station = Radiostation.find_or_create_by(name: 'Sky Radio')
    artist, title, time = check_talpa_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  # Check the Radio Veronica song
  def self.radio_veronica_check
    address = 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-veronica%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D'
    radio_station = Radiostation.find_or_create_by(name: 'Radio Veronica')
    artist, title, time = check_talpa_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  # Check the Radio 538 song
  def self.radio_538_check
    address = 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-538%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 538')
    artist, title, time = check_talpa_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  def self.radio_10_check
    address = 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-10%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 10')
    artist, title, time = check_talpa_radio address
    artist, song = process_track_data(artist, title)
    return false unless artist

    create_generalplaylist(time, artist, song, radio_station)
  end

  #############
  ### OTHER ###
  #############

  def self.q_music_check
    address = 'https://api.qmusic.nl/2.4/tracks/plays?limit=1&next=true'
    radio_station = Radiostation.find_or_create_by(name: 'Qmusic')

    uri = URI address
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      response = http.request(request)
      track = JSON.parse(response.body)['played_tracks'][0]
      time = Time.parse(track['played_at']).strftime('%H:%M')
      artist = find_or_create_artist(track['artist']['name'].titleize)
      title = track['title']

      return unless title_check(title)

      songs = Song.where('lower(title) = ?', title.downcase)
      song = song_check(songs, artist, title)
      create_generalplaylist(time, artist, song, radio_station)
    end
  end

  # Check Sublime FM songs
  def self.sublime_fm_check
    # https://sublime.nl/
    url = 'https://sublime.nl/muziek/'
    doc = Nokogiri::HTML open(url)
    radio_station = Radiostation.find_or_create_by(name: 'Sublime FM')
    artist_name = doc.css('span.title')[0].text.strip
    artist = find_or_create_artist(artist_name)
    # gsub to remove any text between parentenses
    title = doc.css('span.title')[1].text.strip.gsub(/\(.*?\)/, '')
    time = doc.at_css('span.date').text.split(':').take(2).join(':')

    return false unless title_check(title)

    songs = Song.where('lower(title) = ?', title.downcase)
    song = song_check(songs, artist, title)
    create_generalplaylist(time, artist, song, radio_station)
  end

  # Check Groot Nieuws Radio songs
  def self.grootnieuws_radio_check
    url = 'https://www.grootnieuwsradio.nl/muziek/playlist'
    doc = Nokogiri::HTML open(url)
    time = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[1]/span').text
    artist_name = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[2]').text.split.map(&:capitalize).join(" ")
    title = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[3]').text.split.map(&:capitalize).join(" ")
    return false if artist_name.blank?

    return unless title_check(title)

    artist = Artist.find_or_create_by(name: artist_name)
    songs = Song.where(title: title)
    song = song_check(songs, artist, title)
    radiostation = Radiostation.find_or_create_by(name: 'Groot Nieuws Radio')

    create_generalplaylist(time, artist, song, radiostation)
  end

  ##########################
  ### processing methods ###
  ##########################

  def self.process_track_data(artist, title)
    return false unless title_check(title)

    songs = Song.where('lower(title) = ?', title.downcase)
    song = song_check(songs, artist, title)
    [artist, song]
  end

  def self.title_check(title)
    # catch more then 4 digits, forward slashes, 2 single qoutes,
    # reklame/reclame and 2 dots
    !title.match(/\d{4,}|\/|\'{2,}|(reklame|reclame)|\.{2,}/)
  end

  # Methode for checking if there are songs with the same title.
  # if so the artist id must be check
  # if the artist with the some song is not in the database the song with artist Id must be added
  def self.song_check(songs, artist, title)
    # If there is no song with the same title create a new one
    song = if songs.blank?
             Song.find_or_create_by(title: title, artist: artist)
           # If the is a song with the same title check the artist
           else
             songs.each do |s|
               artist_name = s.artist.name
               check_artist = Artist.where(name: artist_name)
               if check_artist.blank?
                 # If there is no song title with the same artist create a new one
                 Song.find_or_create_by(title: title, artist: artist)
               else
                 # Else grap the song record with the same title and artist id
                 Song.find_by(title: title, artist: artist)
               end
             end
           end

    song = song.first if song.is_a?(Array)
    song = Generalplaylist.find_spotify_links(song, artist, title)
    song
  end

  def self.find_or_create_artist(name)
    artists = Artist.where('lower(name) = ?', name.downcase)

    if artists.present?
      # select artist with the most common
      highest_count = 0
      selected = nil
      artists.each do |artist|
        counts = Generalplaylist.joins(:artist)
                                .where('artists.id = ?', artist.id)
                                .group(:artist_id)
                                .count[artist.id]
        selected = artist if counts.nil? || counts > highest_count
      end
      selected
    else
      Artist.create(name: name)
    end
  end

  def self.find_spotify_links(song, artist, title)
    title = title.gsub(/\A\d{3}/, '').strip # opwekking songs
    # Spotify lookup image and song
    if RSpotify::Track.search("#{artist.name} #{title}").present?
      song.spotify_song_url = RSpotify::Track.search("#{artist.name} #{title}").first.external_urls["spotify"]
      song.spotify_artwork_url = @track_album = RSpotify::Track.search("#{artist.name} #{title}").first.album.images[1]["url"]
    end
    song
  end

  # Methode for creating the Generalplaylist record
  def self.create_generalplaylist(time, artist, song, radio_station)
    # Take all the songs that are played on the same radiostation the last 2 days
    radio_station_songs = Generalplaylist.where(radiostation: radio_station,
                                                created_at: 1.day.ago..Time.now)
                                         .order(id: :ASC)
    # If the is no song played the last 2 days create a new one
    if radio_station_songs.blank?
      Generalplaylist.add_song(time, artist, song, radio_station)
    # Else check if the last played song = the same as the song we want to check
    else
      @songs_recently_played = []
      radio_station_songs.each do |radio_station_song|
        if radio_station_song.time == time && radio_station_song.song == song && radio_station_song.artist == artist
          Rails.logger.info "#{song.title} from #{artist.name} in last songs on #{radio_station.name}"
          @songs_recently_played << true
        else
          @songs_recently_played << false
        end
      end
      if @songs_recently_played.exclude? true
        Generalplaylist.add_song(time, artist, song, radio_station)
      end
    end
  end

  # Methode for adding the song to the database
  def self.add_song(time, artist, song, radio_station)
    fullname = "#{artist.name} #{song.title}"
    # Create a new Generalplaylist record
    Generalplaylist.create(
      time: time,
      artist: artist,
      song: song,
      radiostation: radio_station
    )
    song.update(fullname: fullname, artist: artist)

    Rails.logger.info "Saved #{song.title} (#{song.id}) from #{artist.name} (#{artist.id}) on #{radio_station.name}!"
  end

  def self.check_all_radiostations
    # npo stations
    radio_1_check
    radio_2_check
    radio_3fm_check
    radio_4_check
    radio_5_check
    # talpa station
    radio_538_check
    sky_radio_check
    radio_veronica_check
    radio_10_check
    # other stations
    q_music_check
    sublime_fm_check
    grootnieuws_radio_check
  end

  # fetch the top 10 songs played from a radiostation
  def self.top_songs_radiostation(radiostation_id)
    # get all the songs played by the radiostation
    all_from_radiostation = Generalplaylist.where(radiostation_id: radiostation_id)
    # group all the by song_id and count all the time the song_id is in the list. Returns a hash
    top_songs_hash = all_from_radiostation.group(:song_id).count
    # Sort the hash by the value and reverse the order. Show only the first 10 results
    top_songs = top_songs_hash.sort_by { |_key, value| value }.reverse[0 .. 9]
    # resturn the array from song_id with counts
    top_songs
  end

  def self.top_artists_radiostation(radiostation_id)
    all_from_radiostation = Generalplaylist.where(radiostation_id: radiostation_id)
    top_artists_hash = all_from_radiostation.group(:artist_id).count
    top_artists = top_artists_hash.sort_by{ |_key, value| value }.reverse[0 .. 9]
    top_artists
  end

  def autocomplete
    autocomplete.try(:fullname)
  end

  def autocomplete=(fullname)
    self.autocomplete = Song.find_by_fullname(fullname, include: :id) if fullname.present?
  end

  def self.get_artist_songs_title_time(doc)
    time = doc.xpath('//html/body/div[3]/div[2]/div[1]/div[1]/div[3]/div[1]').text.strip
    artist_name = doc.xpath('//html/body/div[3]/div[2]/div[1]/div[1]/div[3]/div[2]/span[2]').text.strip
    title = doc.xpath('//html/body/div[3]/div[2]/div[1]/div[1]/div[3]/div[2]/span[1]').text.strip
 
    title = title.gsub(/\A(Hi:|Topsong:|Nieuwe Naam:)/, '').strip
    # Find the artist name in the Artist database or create a new record
    artist = Artist.find_or_create_by(name: artist_name)
    # Search for all the songs with title
    songs = Song.where(title: title)

    [artist, songs, title, time]
  end

  def self.search(params)
    playlists = Generalplaylist.joins(:artist, :song).order(created_at: :DESC)
    playlists.where!('artists.name ILIKE ? OR songs.fullname ILIKE ?', "%#{params[:search_term]}%", "%#{params[:search_term]}%") if params[:search_term].present?
    playlists.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    playlists
  end
end
