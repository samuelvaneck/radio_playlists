class Playlist < ActiveRecord::Base
  belongs_to :radiostations

  require 'nokogiri'
  require 'open-uri'

  def self.lastplayed(fullname)
    @lastplayed = fullname
    return fullname
  end

  def self.veronica

    url = "http://www.radioveronica.nl/gemist/playlist"
    doc = Nokogiri::HTML(open(url))
    artist = doc.xpath("//tr[@class='active']//td[3]").text
    title = doc.xpath("//tr[@class='active']//td[4]").text
    fullname = "#{artist} #{title}"

    if @lastplayed == fullname
      return false
    else
      playlist = Playlist.find_by_fullname(fullname)

      if playlist != nil
        playlist.counter += 1
        playlist.save
        Playlist.lastplayed(playlist.fullname)
      else
        playlist = Playlist.new
        playlist.image = doc.xpath("//img[@class='playlistimg']/@src").first.text
        playlist.artist = artist
        playlist.title = title
        playlist.fullname = fullname
        playlist.counter = 1
        playlist.save
        Playlist.lastplayed(playlist.fullname)
      end
    end
  end

end
