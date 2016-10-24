class Grootnieuwsplaylist < ActiveRecord::Base

  require 'nokogiri'
  require 'open-uri'
  require 'date'

  validates_presence_of :artist, :title, :time

  def self.sort_today
    order(day_counter: :desc)
  end

  def self.sort_week
    order(week_counter: :desc)
  end

  def self.sort_month
    order(month_counter: :desc)
  end

  def self.sort_year
    order(year_counter: :desc)
  end

  def self.sort_total
    order(total_counter: :desc)
  end

  def self.sort_created
    order(created_at: :desc)
  end

  def self.sort_updated
    order(updated_at: :desc)
  end

  def self.gnr

    # Fetching the data from the website and assinging them to variables
    url = "https://www.grootnieuwsradio.nl/muziek/playlist"
    doc = Nokogiri::HTML(open(url))
    @last_time = doc.xpath('//table[@id="iList1"]/tbody/tr[1]/td[1]').text.split.drop(1).join(" ")
    @last_artist = doc.xpath('//table[@id="iList1"]/tbody/tr[1]/td[2]').text
    @last_title = doc.xpath('//table[@id="iList1"]/tbody/tr[1]/td[3]').text
    @last_fullname = "#{@last_artist} #{@last_title}"

    @second_last_time = doc.xpath('//table[@id="iList1"]/tbody/tr[2]/td[1]').text.split.drop(1).join(" ")
    @second_last_artist = doc.xpath('//table[@id="iList1"]/tbody/tr[2]/td[2]').text
    @second_last_title = doc.xpath('//table[@id="iList1"]/tbody/tr[2]/td[3]').text
    @second_last_fullname = "#{@second_last_artist} #{@second_last_title}"

    @third_last_time = doc.xpath('//table[@id="iList1"]/tbody/tr[3]/td[1]').text.split.drop(1).join(" ")
    @third_last_artist = doc.xpath('//table[@id="iList1"]/tbody/tr[3]/td[2]').text
    @third_last_title = doc.xpath('//table[@id="iList1"]/tbody/tr[3]/td[3]').text
    @third_last_fullname = "#{@third_last_artist} #{@third_last_title}"

    # Methodes for checking songs
    Grootnieuwsplaylist.last_played
    Grootnieuwsplaylist.second_last_played
    Grootnieuwsplaylist.third_last_played

  end

  def self.last_played

    time = @last_time

    # Go to the methode for checking which date the song is played.
    Grootnieuwsplaylist.check_date(time)

    fullname = @last_fullname
    time = @last_time
    date = @date
    artist = @last_artist
    title = @last_title

    # Go to the methode for checking the song
    Grootnieuwsplaylist.song_check(fullname, time, date, artist, title)

  end

  def self.second_last_played

    time = @second_last_time

    # Go to the methode for checking which date the song is played.
    Grootnieuwsplaylist.check_date(time)

    fullname = @second_last_fullname
    time = @second_last_time
    date = @date
    artist = @second_last_artist
    title = @second_last_title

    # Go to the methode for checking the song
    Grootnieuwsplaylist.song_check(fullname, time, date, artist, title)

  end

  def self.third_last_played

    time = @third_last_time

    # Go to the methode for checking which date the song is played.
    Grootnieuwsplaylist.check_date(time)

    fullname = @third_last_fullname
    time = @third_last_time
    date = @date
    artist = @third_last_artist
    title = @third_last_title

    # Go to the methode for checking the song
    Grootnieuwsplaylist.song_check(fullname, time, date, artist, title)

  end

  def self.song_check(fullname, time, date, artist, title)

    # Check if the song hasn't been played lately. It checks the last 6 database records that have been updated or have been created.
    # If the fullname of the song matches a fullname of any of them it doesn't continue.
    if (Grootnieuwsplaylist.order(updated_at: :desc).limit(6).any?{ |playlist| playlist.fullname == fullname }) || (Grootnieuwsplaylist.order(created_at: :desc).limit(6).any?{ |playlist| playlist.fullname == fullname })
      puts "#{fullname} in last 3 songs"
    else
      # Checking if the song fullname is present in the database.
      # If the song is present it increments the counters by one.
      if Grootnieuwsplaylist.where(fullname: fullname).exists?
        @playlist = Grootnieuwsplaylist.find_by_fullname(fullname)
        @playlist.time = time
        @playlist.date = date
        @playlist.day_counter += 1
        @playlist.week_counter += 1
        @playlist.month_counter += 1
        @playlist.year_counter += 1
        @playlist.total_counter += 1
        @playlist.save
        puts "#{fullname} + 1"
      # If the song isn't present it creates a new record
      else
        @playlist = Grootnieuwsplaylist.new
        @playlist.time = time
        @playlist.date = date
        @playlist.artist = artist
        @playlist.title = title
        @playlist.fullname = fullname
        @playlist.day_counter = 1
        @playlist.week_counter = 1
        @playlist.month_counter = 1
        @playlist.year_counter = 1
        @playlist.total_counter = 1
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

  # set the counter equal to one if a new record is made for the song.
  def self.counters_equals_one
    @playlist.day_counter = 1
    @playlist.week_counter = 1
    @playlist.month_counter = 1
    @playlist.year_counter = 1
    @playlist.total_counter = 1
  end

  def self.reset_counters
    songs = Grootnieuwsplaylist.all
    today = Date.today
    # Reset the day counter. Runs everyday at midnight.
    songs.each do |song|
      song.day_counter = 0
      song.save
    end
    # Reset the week counter. Runs Monday at midnight.
    if today.sunday?
      songs.each do |song|
        song.week_counter = 0
        song.save
      end
    end
    # Reset the month counter. Runs at the end of the month.
    if today == Date.today.end_of_month
      songs.each do |song|
        song.month_counter = 0
        song.save
      end
    end
    # Reset the year counter. Runs at the end of the year.
    if today == Date.today.end_of_year
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

  # Methodes for autocomplete search function
  def search_fullname
    Grootnieuwsplaylist.try(:fullname)
  end

  def search_fullname=(fullname)
    self.search_fullname = Grootnieuwsplaylist.find_by_fullname(fullname) if fullname.present?
  end


end
