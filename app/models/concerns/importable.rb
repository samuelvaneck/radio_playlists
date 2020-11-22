# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

module Importable
  extend ActiveSupport::Concern
  include TrackDataProcessor

  module ClassMethods
    def import_song(radio_station)
      unless radio_station
        Rails.logger.info 'No radio station present'
        return false
      end

      artist_name, title, broadcast_timestamp = send(radio_station.processor.to_sym, radio_station)

      return false if artist_name.blank?
      return false if illegal_word_in_title(title)

      artists, song = process_track_data(artist_name, title)
      create_generalplaylist(broadcast_timestamp, artists, song, radio_station)
    end

    def npo_api_processor(radio_station)
      uri = URI radio_station.url
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
        request = Net::HTTP::Get.new(uri, 'Content-Type': 'application/json')
        response = http.request(request)
        json = JSON.parse(response.body)
        raise StandardError if json.blank?

        track = JSON.parse(response.body)['data'][0]
        artist_name = track['artist']
        title = track['title']
        broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['startdatetime'])

        [artist_name, title, broadcast_timestamp]
      end
    rescue Net::ReadTimeout => _e
      Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
    rescue Net::OpenTimeout => _e
      Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
    rescue StandardError => e
      Rails.logger.info e
      false
    end

    def talpa_api_processor(radio_station)
      uri = URI radio_station.url
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
        request = Net::HTTP::Get.new(uri, 'Content-Type': 'application/json')
        response = http.request(request)
        json = JSON.parse(response.body)
        raise StandardError if json.blank?
        raise StandardError if json['errors'].present?

        track = json['data']['getStation']['playouts'][0]
        artist_name = track['track']['artistName']
        title = track['track']['title']
        broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['broadcastDate'])

        [artist_name, title, broadcast_timestamp]
      end
    rescue Net::ReadTimeout => _e
      Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
    rescue Net::OpenTimeout => _e
      Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
    rescue StandardError => _e
      false
    end

    def qmusic_api_processor(radio_station)
      uri = URI radio_station.url
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri, 'Content-Type': 'application/json')
        response = http.request(request)
        track = JSON.parse(response.body)['played_tracks'][0]
        broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['played_at'])
        artist_name = track['artist']['name'].titleize
        title = track['title']

        [artist_name, title, broadcast_timestamp]
      end
    end

    def scraper(radio_station)
      case radio_station.name
      when 'Sublime FM'
        last_hour = "#{Time.zone.now.strftime('%F')} #{Time.zone.now.hour}:00:00"
        next_hour = "#{Time.zone.now.strftime('%F')} #{Time.zone.now.hour == 23 ? '00' : Time.zone.now.hour + 1}:00:00"
        data = `curl 'https://sublime.nl/wp-content/themes/OnAir2ChildTheme/phpincludes/sublime-playlist-query.php' \
                -H 'authority: sublime.nl' \
                -H 'accept: */*' \
                -H 'x-requested-with: XMLHttpRequest' \
                -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 11_0_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36' \
                -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' \
                -H 'origin: https://sublime.nl' \
                -H 'sec-fetch-site: same-origin' \
                -H 'sec-fetch-mode: cors' \
                -H 'sec-fetch-dest: empty' \
                -H 'referer: https://sublime.nl/sublime-playlist/' \
                -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8,nl;q=0.7' \
                -H 'cookie: _gcl_au=1.1.1212470413.1602485820; _ga=GA1.2.971901252.1602485820; sdk_cid=b5849bee-5937-4840-e28c-27e51f04cf0a; _fbp=fb.1.1602485820169.1313290207; _hjid=36b895a3-1f56-4f13-b203-787d6bf3f1fa; wpca_consent=1; wpca_cc=functional,analytical,social-media,advertising,other; _pk_id.1007.19e6=e9aaca32220119ca.1602485820.1.1602485853.1602485820.; cookielawinfo-checkbox-necessary=yes; cookielawinfo-checkbox-non-necessary=yes; CookieLawInfoConsent=eyJuZWNlc3NhcnkiOnRydWUsIm5vbi1uZWNlc3NhcnkiOnRydWV9; viewed_cookie_policy=yes; _gid=GA1.2.1676211182.1606038401; _gat_gtag_UA_34473534_8=1' \
                --data-raw 'request_from=#{last_hour}&request_to=#{next_hour}' \
                --compressed`
        
        playlist = Nokogiri::HTML(data)
        artist_name = playlist.search('.play_artist')[-1].text.strip
        title = playlist.search('.play_title')[-1].text.strip
        time = playlist.search('.play_time')[-1].text.strip
      when 'Groot Nieuws Radio'
        doc = Nokogiri::HTML(URI(radio_station.url).open)
        artist_name = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[2]').text.split.map(&:capitalize).join(' ')
        title = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[3]').text.split.map(&:capitalize).join(' ')
        time = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[1]/span').text
      else
        Rails.logger.info "Radio station #{radio_station.name} not found in SCRAPER"
      end

      [artist_name, title, Time.find_zone('Amsterdam').parse(time)]
    end

    # Methode for creating the Generalplaylist record
    def create_generalplaylist(broadcast_timestamp, artists, song, radio_station)
      last_played_song = Generalplaylist.where(radiostation: radio_station, song: song, broadcast_timestamp: broadcast_timestamp).order(created_at: :desc).first

      if last_played_song.blank?
        add_song(broadcast_timestamp, artists, song, radio_station)
      elsif last_played_song.broadcast_timestamp == broadcast_timestamp && last_played_song.song == song
        Rails.logger.info "#{song.title} from #{Array.wrap(artists).map(&:name).join(', ')} last song on #{radio_station.name}"  
      else
        Rails.logger.info 'No song added'
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

      Rails.logger.info "Saved #{song.title} (#{song.id}) from #{Array.wrap(artists).map(&:name).join(', ')} (#{Array.wrap(artists).map(&:id).join(' ')}) on #{radio_station.name}!"
    end
  end
end
