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

      air_play = Nokogiri::HTML(data)
      return false if air_play.search('.play_artist')[-1].blank?

      @artist_name = air_play.search('.play_artist')[-1].text.strip
      @title = TitleSanitizer.sanitize(air_play.search('.play_title')[-1].text.strip)
      time = air_play.search('.play_time')[-1].text.strip
    else
      Rails.logger.info "Radio station #{@radio_station.name} not found in SCRAPER"
    end

    @broadcasted_at = Time.find_zone('Amsterdam').parse("#{date_string} #{time}")
    true
  end
end
