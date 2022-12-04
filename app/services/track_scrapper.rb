# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

class TrackScrapper

  def initialize(radio_station)
    @radio_station = radio_station
  end

  def latest_track
    send(@radio_station.processor.to_sym)
    {
      artist_name: @artist_name,
      title: @title,
      broadcast_timestamp: @broadcast_timestamp,
      spotify_url: @spotify_url
    }
  end

  private

  def npo_api_processor
    uri = URI @radio_station.url
    json = JSON(make_request)
    raise StandardError if json.blank?

    track = json['data'][0]
    @artist_name = CGI.unescapeHTML(track['artist']).titleize
    @title = CGI.unescapeHTML(track['title']).titleize
    @broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['startdatetime'])
    @spotify_url = track['spotify_url']
  rescue Net::ReadTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
  rescue Net::OpenTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
  rescue StandardError => e
    Rails.logger.info e
    false
  end

  def talpa_api_processor
    uri = URI @radio_station.url
    api_header = { 'x-api-key': ENV['TALPA_API_KEY'] }
    json = JSON(make_request(api_header))
    raise StandardError if json.blank?
    raise StandardError, json['errors'] if json['errors'].present?

    track = json['data']['getStation']['playouts'][0]
    @artist_name = track['track']['artistName']
    @title = track['track']['title']
    @broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['broadcastDate'])
  rescue Net::ReadTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
  rescue Net::OpenTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
  rescue StandardError => e
    Rails.logger.info e.try(:message)
    false
  end

  def qmusic_api_processor
    json = JSON(make_request)
    raise StandardError if json.blank?

    track = json['played_tracks'][0]
    @broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['played_at'])
    @artist_name = track['artist']['name'].titleize
    @title = track['title']
    @spotify_url = track['spotify_url']
  end

  def scraper
    date_string = Time.zone.now.strftime('%F')
    case @radio_station.name
    when 'Sublime FM'
      last_hour = "#{date_string} #{Time.zone.now.hour}:00:00"
      next_hour = "#{date_string} #{Time.zone.now.hour == 23 ? '00' : Time.zone.now.hour + 1}:00:00"
      data = `curl 'https://sublime.nl/wp-content/themes/OnAir2ChildTheme/phpincludes/sublime-playlist-query-api.php' \
              --data-raw 'request_from=#{last_hour}&request_to=#{next_hour}'`

      playlist = Nokogiri::HTML(data)
      return [] if playlist.search('.play_artist')[-1].blank?

      @artist_name = playlist.search('.play_artist')[-1].text.strip
      @title = playlist.search('.play_title')[-1].text.strip
      time = playlist.search('.play_time')[-1].text.strip
    when 'Groot Nieuws Radio'
      doc = Nokogiri::HTML(URI(@radio_station.url).open)
      @artist_name = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[2]').text.split.map(&:capitalize).join(' ')
      @title = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[3]').text.split.map(&:capitalize).join(' ')
      time = doc.xpath('//*[@id="anchor-sticky"]/article/div/div/div[2]/div[1]/div[1]/span').text
    else
      Rails.logger.info "Radio station #{@radio_station.name} not found in SCRAPER"
    end

    @broadcast_timestamp = Time.find_zone('Amsterdam').parse("#{date_string} #{time}")
  end

  def make_request(additional_headers = nil)
    uri = URI @radio_station.url
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
      headers = { 'Content-Type': 'application/json' }
      headers.merge!(additional_headers) if additional_headers.present?
      request = Net::HTTP::Get.new(uri, headers)
      response = http.request(request)
      response.code == '200' ? response.body : []
    end
  end
end
