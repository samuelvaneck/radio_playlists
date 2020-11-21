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
        Rails.logger.info "No radio station present"
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
        broadcast_timestamp = Time.parse(track['startdatetime']).in_time_zone('Amsterdam')

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
        request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
        response = http.request(request)
        json = JSON.parse(response.body)
        raise StandardError if json.blank?
        raise StandardError if json['errors'].present?

        track = json['data']['getStation']['playouts'][0]
        artist_name = track['track']['artistName']
        title = track['track']['title']
        broadcast_timestamp = Time.parse(track['broadcastDate']).in_time_zone('Amsterdam')

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
        request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
        response = http.request(request)
        track = JSON.parse(response.body)['played_tracks'][0]
        broadcast_timestamp = Time.parse(track['played_at'])
        artist_name = track['artist']['name'].titleize
        title = track['title']

        [artist_name, title, broadcast_timestamp]
      end
    end

    def scraper(radio_station)
      doc = Nokogiri::HTML(URI(radio_station.url).open)
      broadcast_timestamp = Time.zone.now

      case radio_station.name
      when 'Sublime FM'
        artist_name = doc.xpath('//*[@id="qtmainmenucontainer"]/div/div[2]/div[1]/div/div/div[1]/span[2]').text
        # gsub to remove any text between parentenses
        title = doc.xpath('//*[@id="qtmainmenucontainer"]/div/div[2]/div[1]/div/div/div[1]/span[3]').text
      when 'Groot Nieuws Radio'
        artist_name = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[2]').text.split.map(&:capitalize).join(" ")
        title = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[3]').text.split.map(&:capitalize).join(' ')
      else
        Rails.logger.info "Radio station #{radio_station.name} not found in SCRAPER"
      end

      [artist_name, title, broadcast_timestamp]
    end

    # Methode for creating the Generalplaylist record
    def create_generalplaylist(broadcast_timestamp, artists, song, radio_station)
      last_played_song = Generalplaylist.where(radiostation: radio_station, song: song, broadcast_timestamp: broadcast_timestamp).order(created_at: :desc).first

      if last_played_song.blank?
        add_song(broadcast_timestamp, artists, song, radio_station)
      elsif last_played_song.broadcast_timestamp == broadcast_timestamp && last_played_song.song == song
        Rails.logger.info "#{song.title} from #{Array.wrap(artists).map(&:name).join(', ')} last song on #{radio_station.name}"
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
