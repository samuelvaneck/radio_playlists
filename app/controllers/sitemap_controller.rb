# frozen_string_literal: true

class SitemapController < ActionController::API
  FRONTEND_URL = 'https://airplays.nl'

  def show
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
        static_pages(xml)
        radio_station_pages(xml)
        song_pages(xml)
        artist_pages(xml)
      end
    end

    render xml: builder.to_xml
  end

  private

  def static_pages(xml)
    %w[/ /radio_stations /songs /artists].each do |path|
      xml.url do
        xml.loc "#{FRONTEND_URL}#{path}"
        xml.changefreq path == '/' ? 'daily' : 'weekly'
        xml.priority path == '/' ? '1.0' : '0.8'
      end
    end
  end

  def radio_station_pages(xml)
    RadioStation.select(:id, :slug, :updated_at).find_each do |station|
      xml.url do
        xml.loc "#{FRONTEND_URL}/radio_stations/#{station.slug}"
        xml.lastmod station.updated_at.strftime('%Y-%m-%d')
        xml.changefreq 'daily'
        xml.priority '0.8'
      end
    end
  end

  def song_pages(xml)
    Song.select(:id, :updated_at).find_each do |song|
      xml.url do
        xml.loc "#{FRONTEND_URL}/songs/#{song.id}"
        xml.lastmod song.updated_at.strftime('%Y-%m-%d')
        xml.changefreq 'weekly'
        xml.priority '0.6'
      end
    end
  end

  def artist_pages(xml)
    Artist.select(:id, :updated_at).find_each do |artist|
      xml.url do
        xml.loc "#{FRONTEND_URL}/artists/#{artist.id}"
        xml.lastmod artist.updated_at.strftime('%Y-%m-%d')
        xml.changefreq 'weekly'
        xml.priority '0.6'
      end
    end
  end
end
