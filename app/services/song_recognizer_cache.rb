class SongRecognizerCache
  CACHE_EXPIRY = 2.hours

  attr_reader :radio_station_id, :title, :artist_name

  def initialize(**args)
    @radio_station_id = args[:radio_station_id]
    @title = args[:title]
    @artist_name = args[:artist_name]
  end

  def recognized_twice?
    if cache_key_present?
      delete_cache
      true
    else
      create_cache
      false
    end
  end

  private

  def cache_key
    "#{@radio_station_id}-#{@artist_name.downcase.gsub(/\W/, '')}-#{@title.downcase.gsub(/\W/, '')}"
  end

  def cache_key_present?
    Rails.cache.exist?(cache_key)
  end

  def create_cache
    Rails.cache.write(cache_key, Time.zone.now.to_i, expires_in: CACHE_EXPIRY)
  end

  def delete_cache
    Rails.cache.delete(cache_key)
  end
end
