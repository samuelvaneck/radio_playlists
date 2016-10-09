class Radio538playlist < ActiveRecord::Base
  belongs_to :radiostation

  require 'nokogiri'
  require 'open-uri'
  require 'date'

  validates_presence_of :artist, :title, :time

  def self.radio538

    # Fetching the data from the website and assinging them to variables
    url = "https://www.relisten.nl/playlists/538.html"
    doc = Nokogiri::HTML(open(url))
    @last_image = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[1]/a/img/@src').text
    @last_time = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[1]/div/h4/small').text
    @last_artist = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[1]/div/p/a').text
    @last_title = (doc.xpath('//*[@id="playlist"]/div[1]/ul/li[1]/div/h4[@class="media-heading"]').text).split.reverse.drop(1).reverse.join(" ")
    @last_fullname = "#{@last_artist} #{@last_title}"

    @second_last_image = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[2]/a/img/@src').text
    @second_last_time = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[2]/div/h4/small').text
    @second_last_artist = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[2]/div/p/a').text
    @second_last_title = (doc.xpath('//*[@id="playlist"]/div[1]/ul/li[2]/div/h4[@class="media-heading"]').text).split.reverse.drop(1).reverse.join(" ")
    @second_last_fullname = "#{@second_last_artist} #{@second_last_title}"

    @third_last_image = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[3]/a/img/@src').text
    @third_last_time = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[3]/div/h4/small').text
    @third_last_artist = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[3]/div/p/a').text
    @third_last_title = (doc.xpath('//*[@id="playlist"]/div[1]/ul/li[3]/div/h4[@class="media-heading"]').text).split.reverse.drop(1).reverse.join(" ")
    @third_last_fullname = "#{@third_last_artist} #{@third_last_title}"

    # Methodes for checking songs
    Radio538playlist.last_played
    Radio538playlist.second_last_played
    Radio538playlist.third_last_played

  end

  def self.last_played

    time = @last_time

    # Go to the methode for checking which date the song is played.
    Radio538playlist.check_date(time)

    fullname = @last_fullname
    image = @last_image
    time = @last_time
    date = @date
    artist = @last_artist
    title = @last_title

    # Go to the methode for checking the song
    Radio538playlist.song_check(fullname, image, time, date, artist, title)

  end

  def self.second_last_played

    time = @second_last_time

    # Go to the methode for checking which date the song is played.
    Radio538playlist.check_date(time)

    fullname = @second_last_fullname
    image = @second_last_image
    time = @second_last_time
    date = @date
    artist = @second_last_artist
    title = @second_last_title

    # Go to the methode for checking the song
    Radio538playlist.song_check(fullname, image, time, date, artist, title)

  end

  def self.third_last_played

    time = @third_last_time

    # Go to the methode for checking which date the song is played.
    Radio538playlist.check_date(time)

    fullname = @third_last_fullname
    image = @third_last_image
    time = @third_last_time
    date = @date
    artist = @third_last_artist
    title = @third_last_title

    # Go to the methode for checking the song
    Radio538playlist.song_check(fullname, image, time, date, artist, title)

  end

  def self.song_check(fullname, image, time, date, artist, title)

    # Check if the song hasn't been played lately. It checks the last 6 database records that have been updated or have been created.
    # If the fullname of the song matches a fullname of any of them it doesn't continue.
    if (Radio538playlist.order(updated_at: :desc).limit(6).any?{ |playlist| playlist.fullname == fullname }) || (Radio538playlist.order(created_at: :desc).limit(6).any?{ |playlist| playlist.fullname == fullname })
      puts "#{fullname} in last 3 songs"
    else
      # Checking if the song fullname is present in the database.
      # If the song is present it increments the counters by one.
      if Radio538playlist.where(fullname: fullname).exists?
        @playlist = Radio538playlist.find_by_fullname(fullname)
        @playlist.image = image
        @playlist.time = time
        @playlist.date = date
        Radio538playlist.increment_counters
        @playlist.save
        puts "#{fullname} + 1"
      # If the song isn't present it creates a new record
      else
        @playlist = Radio538playlist.new
        @playlist.image = image
        @playlist.time = time
        @playlist.date = date
        @playlist.artist = artist
        @playlist.title = title
        @playlist.fullname = fullname
        Radio538playlist.counters_equals_one
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
    songs = Radio538playlist.all
    songs.each do |song|
      song.day_counter = 0
      song.save
    end
  end

  # Reset the week counter. Runs Monday at midnight.
  def self.reset_week_counters
    today = Date.today
    if today.sunday?
      songs = Radio538playlist.all
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
      songs = Radio538playlist.all
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
      songs = Radio538playlist.all
      songs.each do |song|
        song.year_counter = 0
        song.save
      end
    end
  end

  def self.uniq_tracks_day
    where('updated_at >= ?', DateTime.now.beginning_of_day).count
  end

  def self.uniq_tracks_week
    where('updated_at >= ?', 1.week.ago).count
  end

  def self.uniq_tracks_month
    where('updated_at >= ?', 1.month.ago).count
  end

  def self.uniq_tracks_year
    where('updated_at >= ?', 1.year.ago).count
  end

  def search_fullname
    Radio538playlist.try(:fullname)
  end

  def search_fullname=(fullname)
    self.search_fullname = Radio538playlist.find_by_fullname(fullname) if fullname.present?
  end

end
