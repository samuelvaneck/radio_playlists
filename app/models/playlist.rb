class Playlist < ActiveRecord::Base
  belongs_to :radiostations

  require 'nokogiri'
  require 'open-uri'
  require 'date'

  def self.veronica

    # Fetching the data from the website and assinging them to variables
    url = "http://www.radioveronica.nl/gemist/playlist"
    doc = Nokogiri::HTML(open(url))
    @last_image = doc.xpath("//img[@class='playlistimg']/@src")[0].value
    @last_time = doc.xpath("//tr[@class='active']//td[2]").text
    @last_artist = doc.xpath("//tr[@class='active']//td[3]").text
    @last_title = doc.xpath("//tr[@class='active']//td[4]").text
    @last_fullname = "#{@last_artist} #{@last_title}"
    @second_last_image = doc.xpath("//img[@class='playlistimg']/@src")[1].value
    @second_last_time = doc.xpath("//tr[2]//td[2]").text
    @second_last_artist = doc.xpath("//tr[2]//td[3]").text
    @second_last_title = doc.xpath("//tr[2]//td[4]").text
    @second_last_fullname = "#{@second_last_artist} #{@second_last_title}"
    @third_last_image = doc.xpath("//img[@class='playlistimg']/@src")[2].value
    @third_last_time = doc.xpath("//tr[3]//td[2]").text
    @third_last_artist = doc.xpath("//tr[3]//td[3]").text
    @third_last_title = doc.xpath("//tr[3]//td[4]").text
    @third_last_fullname = "#{@third_last_artist} #{@third_last_title}"

    # Methodes for checking songs
    Playlist.last_played
    Playlist.second_last_played
    Playlist.third_last_played

  end

  def self.last_played

    time = @last_time

    # Go to the methode for checking which date the song is played.
    Playlist.check_date(time)

    fullname = @last_fullname
    image = @last_image
    time = @last_time
    date = @date
    artist = @last_artist
    title = @last_title

    # Go to the methode for checking the song
    Playlist.song_check(fullname, image, time, date, artist, title)

  end

  def self.second_last_played

    time = @second_last_time

    # Go to the methode for checking which date the song is played.
    Playlist.check_date(time)

    fullname = @second_last_fullname
    image = @second_last_image
    time = @second_last_time
    date = @date
    artist = @second_last_artist
    title = @second_last_title

    # Go to the methode for checking the song
    Playlist.song_check(fullname, image, time, date, artist, title)

  end

  def self.third_last_played

    time = @third_last_time

    # Go to the methode for checking which date the song is played.
    Playlist.check_date(time)

    fullname = @third_last_fullname
    image = @third_last_image
    time = @third_last_time
    date = @date
    artist = @third_last_artist
    title = @third_last_title

    # Go to the methode for checking the song
    Playlist.song_check(fullname, image, time, date, artist, title)

  end

  def self.song_check(fullname, image, time, date, artist, title)

    # Check if the song hasn't been played lately. It checks the last 6 database records that have been updated or have been created.
    # If the fullname of the song matches a fullname of any of them it doesn't continue.
    if (Playlist.order(updated_at: :desc).limit(6).any?{ |playlist| playlist.fullname == fullname }) || (Playlist.order(created_at: :desc).limit(6).any?{ |playlist| playlist.fullname == fullname })
      puts "#{fullname} in last 3 songs"
    else
      # Checking if the song fullname is present in the database.
      # If the song is present it increments the counters by one.
      if Playlist.where(fullname: fullname).exists?
        @playlist = Playlist.find_by_fullname(fullname)
        @playlist.image = image
        @playlist.time = time
        @playlist.date = date
        Playlist.increment_counters
        @playlist.save
        puts "#{fullname} + 1"
      # If the song isn't present it creates a new record
      else
        @playlist = Playlist.new
        @playlist.image = image
        @playlist.time = time
        @playlist.date = date
        @playlist.artist = artist
        @playlist.title = title
        @playlist.fullname = fullname
        Playlist.counters_equals_one
        @playlist.save
        puts "#{fullname} added to the database"
      end
    end

  end

  # Methode for defining the date the song is played.
  # if the time in current time zone (Amsterdam) is past midnight and the played song
  # is played at 23h the date is set to yesterday.
  def self.check_date(time)
    if (Time.zone.now.strftime("%H").to_i == 0) && (time[0..-4].to_i == 23)
      @date = Date.yesterday
      @date.strftime("%d %B %Y")
    # if not the current date is set as the date the song is played
    else
      @date = Time.zone.now.strftime("%d %B %Y")
    end
  end

  # increment the counters by one. Methode for when the song is allready in the database.
  def self.increment_counters
    @playlist.day_counter += 1
    @playlist.week_counter += 1
    @playlist.month_counter += 1
    @playlist.year_counter += 1
    @playlist.total_counter += 1
  end

  # set the counter equal to one if a new record is made for the song.
  def self.counters_equals_one
    @playlist.day_counter = 1
    @playlist.week_counter = 1
    @playlist.month_counter = 1
    @playlist.year_counter = 1
    @playlist.total_counter = 1
  end

  # Reset the day counter. Runs everyday at midnight.
  def self.reset_day_counters
    songs = Playlist.all
    songs.each do |song|
      song.day_counter = 0
      song.save
    end
  end

  # Reset the week counter. Runs Monday at midnight.
  def self.reset_week_counters
    today = Date.today
    if today.sunday?
      songs = Playlist.all
      songs.each do |song|
        song.week_counter = 0
        song.save
      end
    end
  end

  # Reset the month counter. Runs at the end of the month.
  def self.reset_month_counters
    today = Date.today
    if today == Date.today.end_of_month
      songs = Playlist.all
      songs.each do |song|
        song.month_counter = 0
        song.save
      end
    end
  end

  # Reset the year counter. Runs at the end of the year.
  def self.reset_year_counters
    today = Date.today
    if today == Date.today.end_of_year
      songs = Playlist.all
      songs.each do |song|
        song.year_counter = 0
        song.save
      end
    end
  end

end
