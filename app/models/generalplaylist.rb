# frozen_string_literal: true

class Generalplaylist < ActiveRecord::Base
  belongs_to :song
  has_many :artists, through: :song
  belongs_to :radiostation

  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def self.check_npo_radio(address)
    uri = URI address

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
      request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      response = http.request(request)
      json = JSON.parse(response.body)
      raise StandardError if json.blank?

      track = JSON.parse(response.body)['data'][0]
      artist_name = track['artist']
      title = track['title']
      time = Time.parse(track['startdatetime']).strftime('%H:%M')

      [artist_name, title, time]
    end
  rescue Net::ReadTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
  rescue Net::OpenTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
  rescue StandardError => _e
    false
  end

  def self.check_talpa_radio(address)
    uri = URI address

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
      request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      response = http.request(request)
      json = JSON.parse(response.body)
      raise StandardError if json.blank?
      raise StandardError if json['errors'].present?

      track = json['data']['getStation']['playouts'][0]
      artist_name = track['track']['artistName']
      title = track['track']['title']
      time = Time.parse(track['broadcastDate']).in_time_zone('Amsterdam').strftime('%H:%M')

      [artist_name, title, time]
    end
  rescue Net::ReadTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
  rescue Net::OpenTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
  rescue StandardError => _e
    false
  end

  ###########
  ### NPO ###
  ###########

  def self.radio_1_check
    address = 'https://www.nporadio1.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 1')
    artist_name, title, time = check_npo_radio address
    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
  end

  # Check Radio 2 song
  def self.radio_2_check
    address = 'https://www.nporadio2.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 2')
    artist_name, title, time = check_npo_radio address
    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
  end

  def self.radio_3fm_check
    address = 'https://www.npo3fm.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 3FM')
    artist_name, title, time = check_npo_radio address
    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
  end

  def self.radio_4_check
    address = 'https://www.nporadio4.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 4')
    artist_name, title, time = check_npo_radio address
    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
  end

  def self.radio_5_check
    address = 'https://www.nporadio5.nl/api/tracks'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 5')
    artist_name, title, time = check_npo_radio address
    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
  end

  #############
  ### TALPA ###
  #############

  def self.sky_radio_check
    address = 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22sky-radio%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D'
    radio_station = Radiostation.find_or_create_by(name: 'Sky Radio')
    artist_name, title, time = check_talpa_radio address
    return false unless artist_name

    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
  end

  # Check the Radio Veronica song
  def self.radio_veronica_check
    address = 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-veronica%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D'
    radio_station = Radiostation.find_or_create_by(name: 'Radio Veronica')
    artist_name, title, time = check_talpa_radio address
    return false unless artist_name
    
    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
  end

  # Check the Radio 538 song
  def self.radio_538_check
    address = 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-538%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 538')
    artist_name, title, time = check_talpa_radio address
    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
  end

  def self.radio_10_check
    address = 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-10%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D'
    radio_station = Radiostation.find_or_create_by(name: 'Radio 10')
    artist_name, title, time = check_talpa_radio address
    artists, song = process_track_data(artist_name, title)
    return false if artists.blank?

    create_generalplaylist(time, artists, song, radio_station)
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
      artist_name = track['artist']['name'].titleize
      title = track['title']

      return false unless title_check(title)

      artists = find_or_create_artist(artist_name, title)
      songs = Song.where('lower(title) = ?', title.downcase)
      song = song_check(songs, artists, title)
      create_generalplaylist(time, artists, song, radio_station)
    end
  end

  # Check Sublime FM songs
  def self.sublime_fm_check
    # https://sublime.nl/
    url = 'https://sublime.nl/muziek/'
    doc = Nokogiri::HTML open(url)
    radio_station = Radiostation.find_or_create_by(name: 'Sublime FM')
    artist_name = doc.css('span.title')[0].text.strip
    # gsub to remove any text between parentenses
    title = doc.css('span.title')[1].text.strip.gsub(/\(.*?\)/, '')
    time = doc.at_css('span.date').text.split(':').take(2).join(':')

    return false unless title_check(title)

    artists = find_or_create_artist(artist_name, title)
    songs = Song.where('lower(title) = ?', title.downcase)
    song = song_check(songs, artists, title)
    create_generalplaylist(time, artists, song, radio_station)
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

    artists = find_or_create_artist(artist_name, title)
    songs = Song.where(title: title)
    song = song_check(songs, artists, title)
    radiostation = Radiostation.find_or_create_by(name: 'Groot Nieuws Radio')

    create_generalplaylist(time, artists, song, radiostation)
  end

  ##########################
  ### processing methods ###
  ##########################

  def self.process_track_data(artist_name, title)
    return false unless title_check(title)

    artists = find_or_create_artist(artist_name, title)
    songs = Song.where('lower(title) = ?', title.downcase)
    song = song_check(songs, artists, title)
    [artists, song]
  end

  def self.title_check(title)
    # catch more then 4 digits, forward slashes, 2 single qoutes,
    # reklame/reclame and 2 dots
    !title.match(/\d{4,}|\/|'{2,}|(reklame|reclame)|\.{2,}/)
  end

  # Methode for checking if there are songs with the same title.
  # if so the artist id must be check
  # if the artist with the some song is not in the database the song with artist Id must be added
  def self.song_check(songs, artists, title)
    # If there is no song with the same title create a new one
    song = if songs.blank?
             Song.find_or_create_by(title: title)
           # If the is a song with the same title check the artist
           else
             songs.each do |_s|
               if artists.blank?
                 # If there is no song title with the same artist create a new one
                 Song.find_or_create_by(title: title)
               else
                 # Else grap the song record with the same title and artist id
                 songs = Song.joins(:artists).where(artists: { id: Array.wrap(artists).map(&:id) })
               end
             end
           end

    song = song.first if song.is_a?(Array)
    song = Generalplaylist.find_spotify_links(song, artists, title)
    song
  end

  def self.find_or_create_artist(name, song_title)
    track = RSpotify::Track.search("#{name} #{song_title}").sort_by(&:popularity).reverse.first

    if track.present?
      track.artists.map(&:name).map do |artist_name|
        Artist.find_or_create_by(name: artist_name)
      end
    else
      Artist.find_or_create_by(name: name)
    end
  end

  def self.find_spotify_links(song, artists, title)
    title = title.gsub(/\A\d{3}/, '').strip # opwekking songs
    artist_names = Array.wrap(artists).map(&:name).join(' ')
    tracks = RSpotify::Track.search("#{artist_names} #{title}").sort_by(&:popularity).reverse
    # Spotify lookup image and song
    if tracks.present?
      song.spotify_song_url = tracks.first.external_urls["spotify"]
      song.spotify_artwork_url = tracks.first.album.images[1]["url"]
    end
    song
  end

  # Methode for creating the Generalplaylist record
  def self.create_generalplaylist(time, artists, song, radio_station)
    last_played_song = Generalplaylist.where(radiostation: radio_station, song: song, time: time).order(created_at: :desc).first
    if last_played_song.blank?
      Generalplaylist.add_song(time, artists, song, radio_station)
    elsif last_played_song.time == time && last_played_song.song == song
      Rails.logger.info "#{song.title} from #{Array.wrap(artists).map(&:name).join(', ')} last song on #{radio_station.name}"
    end
  end

  # Methode for adding the song to the database
  def self.add_song(time, artists, song, radio_station)
    fullname = "#{Array.wrap(artists).map(&:name).join(' ')} #{song.title}"
    # Create a new Generalplaylist record
    Generalplaylist.create(
      time: time,
      song: song,
      radiostation: radio_station
    )
    song.update(fullname: fullname)

    # cleaning up artists
    song.artists.delete_all
    Array.wrap(artists).each do |artist|
      next if song.artists.include? artist

      song.artists << artist
    end

    Rails.logger.info "Saved #{song.title} (#{song.id}) from #{Array.wrap(artists).map(&:name).join(', ')} (#{Array.wrap(artists).map(&:id).join(' ')}) on #{radio_station.name}!"
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
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time =  params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    playlists = Generalplaylist.joins(:song, :artists).order(created_at: :DESC)
    playlists.where!('artists.name ILIKE ? OR songs.title ILIKE ?', "%#{params[:search_term]}%", "%#{params[:search_term]}%") if params[:search_term].present?
    playlists.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    playlists.where!('generalplaylists.created_at > ?', start_time)
    playlists.where!('generalplaylists.created_at < ?', end_time)
    playlists
  end
end
