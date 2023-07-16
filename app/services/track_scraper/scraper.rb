# frozen_string_literal: true

class TrackScraper::Scraper < TrackScraper
  def last_played_song
    date_string = Time.zone.now.strftime('%F')
    case @radio_station.name
    when 'Sublime FM'
      last_hour = "#{date_string} #{Time.zone.now.hour}:00:00"
      next_hour = "#{date_string} #{Time.zone.now.hour == 23 ? '00' : Time.zone.now.hour + 1}:00:00"
      data = `curl 'https://sublime.nl/wp-content/themes/OnAir2ChildTheme/phpincludes/sublime-playlist-query-api.php' \
              --data-raw 'request_from=#{last_hour}&request_to=#{next_hour}'`

      playlist = Nokogiri::HTML(data)
      return false if playlist.search('.play_artist')[-1].blank?

      @artist_name = playlist.search('.play_artist')[-1].text.strip
      @title = playlist.search('.play_title')[-1].text.strip
      time = playlist.search('.play_time')[-1].text.strip
    else
      Rails.logger.info "Radio station #{@radio_station.name} not found in SCRAPER"
    end

    @broadcast_timestamp = Time.find_zone('Amsterdam').parse("#{date_string} #{time}")
    true
  end
end
