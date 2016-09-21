class Playlist < ActiveRecord::Base
  belongs_to :radiostations

  require 'nokogiri'
  require 'open-uri'

  @lastplayed_songs = Playlist.order(updated_at: :desc).limit(3)
  @full_playlist = Playlist.all

  def self.veronica

    url = "http://www.radioveronica.nl/gemist/playlist"
    doc = Nokogiri::HTML(open(url))
    @last_image = doc.xpath("//img[@class='playlistimg']/@src")[0].value
    @last_artist = doc.xpath("//tr[@class='active']//td[3]").text
    @last_title = doc.xpath("//tr[@class='active']//td[4]").text
    @last_fullname = "#{@last_artist} #{@last_title}"
    @second_last_image = doc.xpath("//img[@class='playlistimg']/@src")[1].value
    @second_last_artist = doc.xpath("//tr[2]//td[3]").text
    @second_last_title = doc.xpath("//tr[2]//td[4]").text
    @second_last_fullname = "#{@second_last_artist} #{@second_last_title}"
    @third_last_image = doc.xpath("//img[@class='playlistimg']/@src")[2].value
    @third_last_artist = doc.xpath("//tr[3]//td[3]").text
    @third_last_title = doc.xpath("//tr[3]//td[4]").text
    @third_last_fullname = "#{@third_last_artist} #{@third_last_title}"

    Playlist.last_played
    Playlist.second_last_played
    Playlist.third_last_played

  end

  def self.last_played

    if @lastplayed_songs.where(fullname: @last_fullname) != []
      return false
    else
      if @full_playlist.where(fullname: @last_fullname) != []
        playlist = Playlist.find_by_fullname(@last_fullname)
        playlist.image = @last_image
        playlist.counter += 1
        playlist.save!
      else
        playlist = Playlist.new
        playlist.image = @last_image
        playlist.artist = @last_artist
        playlist.title = @last_title
        playlist.fullname = @last_fullname
        playlist.counter = 1
        playlist.save
      end
    end
  end

  def self.second_last_played

    if @lastplayed_songs.where(fullname: @second_last_fullname) != []
      return false
    else
      if @full_playlist.where(fullname: @second_last_fullname) != []
        playlist = Playlist.find_by_fullname(@second_last_fullname)
        playlist.image = @second_last_image
        playlist.counter += 1
        playlist.save!
      else
        playlist = Playlist.new
        playlist.image = @second_last_image
        playlist.artist = @second_last_artist
        playlist.title = @second_last_title
        playlist.fullname = @second_last_fullname
        playlist.counter = 1
        playlist.save
      end
    end
  end

  def self.third_last_played

    if @lastplayed_songs.where(fullname: @third_last_fullname) != []
      return false
    else
      if @full_playlist.where(fullname: @third_last_fullname) != []
        playlist = Playlist.find_by_fullname(@third_last_fullname)
        playlist.image = @third_last_image
        playlist.counter += 1
        playlist.save!
      else
        playlist = Playlist.new
        playlist.image = @third_last_image
        playlist.artist = @third_last_artist
        playlist.title = @third_last_title
        playlist.fullname = @third_last_fullname
        playlist.counter = 1
        playlist.save
      end
    end
  end

end
