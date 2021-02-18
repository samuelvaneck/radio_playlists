# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

module Importable
  extend ActiveSupport::Concern
  include TrackDataProcessor

  def npo_api_processor
    radio_station = self
    uri = URI radio_station.url
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
      request = Net::HTTP::Get.new(uri, 'Content-Type': 'application/json')
      response = http.request(request)
      json = JSON.parse(response.body)
      raise StandardError if json.blank?

      track = JSON.parse(response.body)['data'][0]
      artist_name = CGI.unescapeHTML(track['artist']).titleize
      title = CGI.unescapeHTML(track['title']).titleize
      broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['startdatetime'])
      spotify_url = track['spotify_url']

      {
        artist_name: artist_name, 
        title: title,
        broadcast_timestamp: broadcast_timestamp,
        spotify_url: spotify_url
      }
    end
  rescue Net::ReadTimeout => _e
    puts "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
  rescue Net::OpenTimeout => _e
    puts "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
  rescue StandardError => e
    puts e
    false
  end

  def talpa_api_processor
    radio_station = self
    data = `curl '#{radio_station.url}' \
          -H 'x-api-key: #{ENV['TALPA_API_KEY']}' \
          -H 'content-type: application/json'`
    
    json = JSON.parse(data)
    raise StandardError if json.blank?
    raise StandardError if json['errors'].present?

    track = json['data']['getStation']['playouts'][0]
    artist_name = track['track']['artistName']
    title = track['track']['title']
    broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['broadcastDate'])

    {
      artist_name: artist_name, 
      title: title,
      broadcast_timestamp: broadcast_timestamp
    }
  rescue Net::ReadTimeout => _e
    puts "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
  rescue Net::OpenTimeout => _e
    puts "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
  rescue StandardError => e
    puts e
    false
  end

  def qmusic_api_processor
    radio_station = self
    uri = URI radio_station.url
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri, 'Content-Type': 'application/json')
      response = http.request(request)
      track = JSON.parse(response.body)['played_tracks'][0]
      broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['played_at'])
      artist_name = track['artist']['name'].titleize
      title = track['title']
      spotify_url = track['spotify_url']

      {
        artist_name: artist_name, 
        title: title,
        broadcast_timestamp: broadcast_timestamp,
        spotify_url: spotify_url
      }
    end
  end

  def scraper
    radio_station = self
    date_string = Time.zone.now.strftime('%F')
    case radio_station.name
    when 'Sublime FM'
      last_hour = "#{date_string} #{Time.zone.now.hour}:00:00"
      next_hour = "#{date_string} #{Time.zone.now.hour == 23 ? '00' : Time.zone.now.hour + 1}:00:00"
      data = `curl 'https://sublime.nl/wp-content/themes/OnAir2ChildTheme/phpincludes/sublime-playlist-query.php' \
              -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' \
              --data-raw 'request_from=#{last_hour}&request_to=#{next_hour}'`

      playlist = Nokogiri::HTML(data)
      return [] if playlist.search('.play_artist')[-1].blank?

      artist_name = playlist.search('.play_artist')[-1].text.strip
      title = playlist.search('.play_title')[-1].text.strip
      time = playlist.search('.play_time')[-1].text.strip
    when 'Groot Nieuws Radio'
      doc = Nokogiri::HTML(URI(radio_station.url).open)
      artist_name = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[2]').text.split.map(&:capitalize).join(' ')
      title = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[3]').text.split.map(&:capitalize).join(' ')
      time = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[1]/span').text
    else
      puts "Radio station #{radio_station.name} not found in SCRAPER"
    end

    broadcast_timestamp = Time.find_zone('Amsterdam').parse("#{date_string} #{time}") 

    {
      artist_name: artist_name, 
      title: title,
      broadcast_timestamp: broadcast_timestamp
    }
  end

  # Methode for creating the Generalplaylist record
  def create_generalplaylist(broadcast_timestamp, artists, song, radio_station)
    last_played_song = Generalplaylist.where(radiostation: radio_station, song: song, broadcast_timestamp: broadcast_timestamp).order(created_at: :desc).first

    if last_played_song.blank?
      add_song(broadcast_timestamp, artists, song, radio_station)
    elsif last_played_song.broadcast_timestamp == broadcast_timestamp && last_played_song.song == song
      puts "#{song.title} from #{Array.wrap(artists).map(&:name).join(', ')} last song on #{radio_station.name}"  
    else
      puts 'No song added'
    end
  end

  # Methode for adding the song to the database
  def add_song(broadcast_timestamp, artists, song, radio_station)
    fullname = "#{Array.wrap(artists).map(&:name).join(' ')} #{song.title}"
    # Create a new Generalplaylist record
    Generalplaylist.create(
      broadcast_timestamp: broadcast_timestamp,
      song: song,
      radiostation: radio_station
    )
    song.update(fullname: fullname)

    # cleaning up artists
    song.artists.clear
    Array.wrap(artists).each do |artist|
      next if song.artists.include? artist

      song.artists << artist
    end

    puts "Saved #{song.title} (#{song.id}) from #{Array.wrap(artists).map(&:name).join(', ')} (#{Array.wrap(artists).map(&:id).join(' ')}) on #{radio_station.name}!"
  end
end
