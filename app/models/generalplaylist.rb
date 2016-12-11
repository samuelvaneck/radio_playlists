class Generalplaylist < ActiveRecord::Base
  belongs_to :song
  belongs_to :radiostation
  belongs_to :artist

  require 'nokogiri'
  require 'open-uri'
  require 'date'

  # Check the Radio Veronica song
  def self.radio_veronica_check
    url = "http://playlist24.nl/radio-veronica-playlist/"
    doc = Nokogiri::HTML(open(url))
    time = doc.xpath('/html/body/div[3]/div[2]/div[1]/div[3]/div[1]').text.squish
    artist = doc.xpath('/html/body/div[3]/div[2]/div[1]/div[3]/div[2]/span[2]/a').text.camelcase
    title = doc.xpath('/html/body/div[3]/div[2]/div[1]/div[3]/div[2]/span[1]/a').text.camelcase

    # Find the artist name in the Artist database or create a new record
    artist = Artist.find_or_create_by(name:artist)
    # Search for all the songs with title
    songs = Song.where("title = ?", title)
    # Add the songs variable to the song_check methode. Return @song variable
    Generalplaylist.song_check(songs, artist, title)
    # Find or create the Radiostation with name "Radio Veronica"
    radiostation = Radiostation.find_or_create_by(name: "Radio Veronica")

    # Create a item in the Generalplaylist model with time, artist, @song and radiostation variable
    Generalplaylist.create_generalplaylist(time, artist, @song, radiostation)
  end

  # Check the Radio 538 song
  def self.radio_538_check
    url = "https://www.relisten.nl/playlists/538.html"
    doc = Nokogiri::HTML(open(url))
    time = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[1]/div/h4/small').text
    artist = doc.xpath('//*[@id="playlist"]/div[1]/ul/li[1]/div/p/a').text.camelcase
    title = (doc.xpath('//*[@id="playlist"]/div[1]/ul/li[1]/div/h4[@class="media-heading"]').text).split.reverse.drop(1).reverse.join(" ").camelcase

    # Find the artist name in the Artist database or create a new record
    artist = Artist.find_or_create_by(name: artist)
    # Search for all the songs with title
    songs = Song.where("title = ?", title)
    # Add the songs variable to the song_check methode. Returns @song variable
    Generalplaylist.song_check(songs, artist, title)
    # Find or create the Radiostation with name "Radio 538"
    radiostation = Radiostation.find_or_create_by(name: "Radio 538")

    # Create a item in the Generalplaylist model with time, artist, @song and radiostation variable
    Generalplaylist.create_generalplaylist(time, artist, @song, radiostation)
  end

  # Check Radio 2 song
  def self.radio_2_check

    topsong = "TOPSONG: "
    hi = "HI: "
    nieuwe_naam = "NIEUW NAAM: "

    url = "http://www.nporadio2.nl/playlist"
    doc = Nokogiri::HTML(open(url))
    list = doc.at('.columns-2')
    time = list.xpath('//li[last()]/a/div[3]/div/p').first.text
    artist = list.xpath('//li[last()]/a/div[2]/div/p[1]').first.text.camelcase
    title = list.xpath('//li[last()]/a/div[2]/div/p[2]').first.text.camelcase

    # check if the variables topsong, hi or nieuwe_naam are in the title
    # if so they will be sliced off
    if title.include?(topsong)
      title.slice!(topsong)
    elsif title.include?(hi)
      title.slice!(hi)
    elsif title.include?(nieuwe_naam)
      title.slice!(nieuwe_naam)
    end

    # Find the artist name in the Artist database or create a new record
    artist = Artist.find_or_create_by(name: artist)
    # Search for all the songs with title
    songs = Song.where("title = ?", title)
    # Add the songs variable to the song_check methode. Returns @song variable
    Generalplaylist.song_check(songs, artist, title)
    # Find or create the Radiostation with name "Radio 2"
    radiostation = Radiostation.find_or_create_by(name: "Radio 2")

    # Create a item in the Generalplaylist model with time, artist, @song and radiostation variable
    Generalplaylist.create_generalplaylist(time, artist, @song, radiostation)
  end

  # Check Sublime FM songs
  def self.sublime_fm_check
    url = "http://playlist24.nl/sublime-fm-playlist/"
    doc = Nokogiri::HTML(open(url))
    time = doc.xpath('/html/body/div[3]/div[2]/div[1]/div[3]/div[1]').text.squish
    artist = doc.xpath('/html/body/div[3]/div[2]/div[1]/div[3]/div[2]/span[2]/a').text.camelcase
    title = doc.xpath('/html/body/div[3]/div[2]/div[1]/div[3]/div[2]/span[1]/a').text.camelcase

    # Find the artist name in the Artist database or create a new record
    artist = Artist.find_or_create_by(name: artist)
    # Search for all the songs with title
    songs = Song.where("title = ?", title)
    # Add the songs variable to the song_check methode. Returns @song variable
    Generalplaylist.song_check(songs, artist, title)
    # Find or create the Radiostation with name "Sublime FM"
    radiostation = Radiostation.find_or_create_by(name: "Sublime FM")

    # Create a item in the Generalplaylist model with time, artist, @song and radiostation variable
    Generalplaylist.create_generalplaylist(time, artist, @song, radiostation)
  end

  # Check Groot Nieuws Radio songs
  def self.grootnieuws_radio_check
    url = "https://www.grootnieuwsradio.nl/muziek/playlist"
    doc = Nokogiri::HTML(open(url))
    time = doc.xpath('//table[@id="iList1"]/tbody/tr[1]/td[1]').text.split.drop(1).join(" ")
    artist = doc.xpath('//table[@id="iList1"]/tbody/tr[1]/td[2]').text.camelcase
    title = doc.xpath('//table[@id="iList1"]/tbody/tr[1]/td[3]').text.camelcase

    # Find the artist name in the Artist database or create a new record
    artist = Artist.find_or_create_by(name: artist)
    # Search for all the songs with title
    songs = Song.where("title = ?", title)
    # Add the songs variable to the song_check methode. Returns @song variable
    Generalplaylist.song_check(songs, artist, title)
    # Find or create the Radiostation with name "Groot Nieuws Radio"
    radiostation = Radiostation.find_or_create_by(name: "Groot Nieuws Radio")

    # Create a item in the Generalplaylist model with time, artist, @song and radiostation variable
    Generalplaylist.create_generalplaylist(time, artist, @song, radiostation)
  end

  # Methode for checking if there are songs with the same title.
  # if so the artist id must be check
  # if the artist with the some song is not in the database the song with artist Id must be added
  def self.song_check(songs, artist, title)
    # If there is no song with the same title create a new one
    if songs == []
      @song = Song.find_or_create_by(title: title, artist: artist)
    # If the is a song with the same title check the artist
    else
      songs.each do |s|
        artist_name = s.artist.name
        check_artist = Artist.where("name = ?", artist_name)
        # Ef there is no song title with the same artist create a new one
        if check_artist == []
          @song = Song.find_or_create_by(title: title, artist: artist)
        # Else grap the song record with the same title and artist id
        else
          @song = Song.find_by_title_and_artist_id(title, artist.id)
        end
      end
    end
    # Return @song variable
    return @song
  end

  # Methode for creating the Generalplaylist record
  def self.create_generalplaylist(time, artist, song, radiostation)
    # Take all the songs that are played on the same radiostation the last 2 days
    radiostationsongs = Generalplaylist.where("radiostation_id = ? AND created_at > ?", radiostation.id, 2.day.ago)
    # If the is no song played the last 2 days create a new one
    if radiostationsongs == []
      Generalplaylist.add_song(time, artist, song, radiostation)
    # Else check if the last played song = the same as the song we want to check
    else
      if (radiostationsongs.last.time == time) && (radiostationsongs.last.song_id == song.id) && (radiostationsongs.last.artist_id == artist.id)
        puts "#{song.title} from #{artist.name} in last 3 songs on #{radiostation.name}"
        return false
      else
        # add the song to the song to the database
        Generalplaylist.add_song(time, artist, song, radiostation)
      end
    end
  end

  # Methode for adding the song to the database
  def self.add_song(time, artist, song, radiostation)

    # Create a new Generalplaylist record
    generalplaylist = Generalplaylist.new
    generalplaylist.time = time
    generalplaylist.artist_id = artist.id
    generalplaylist.song_id = song.id
    generalplaylist.radiostation_id = radiostation.id
    generalplaylist.save!
    fullname = "#{artist.name} #{song.title}"
    # Add 1 to the song total counters
    songdetails = Song.find(generalplaylist.song_id)
    songdetails.day_counter += 1
    songdetails.week_counter += 1
    songdetails.month_counter += 1
    songdetails.year_counter += 1
    songdetails.total_counter += 1
    songdetails.fullname = fullname
    songdetails.artist_id = artist.id
    songdetails.save!
    # Add 1 to the artist counters
    artist = Artist.find(generalplaylist.artist_id)
    artist.day_counter += 1
    artist.week_counter += 1
    artist.month_counter += 1
    artist.year_counter += 1
    artist.total_counter += 1
    artist.save!
    puts "Saved #{song.title} from #{artist.name} on #{radiostation.name}!"
  end

  # Methode for resetting the day, week, month and year counters
  def self.reset_counters
    songs = Song.all
    artists = Artists.all
    today = Date.today
    # reset the day counter for songs and artists
    songs.each do |song|
      song.day_counter = 0
      song.save
    end
    artists.each do |artist|
      artist.day_counter = 0
      artist.save
    end
    # reset the week counter if today is monday
    if today.monday?
      songs.each do |song|
        song.week_counter = 0
        song.save
      end
      artists.each do |artist|
        artist.week_counter = 0
        artist.save
      end
    end
    # reset the month counter at the end of the month
    if today == Date.today.end_of_month
      songs.each do |song|
        song.month_counter = 0
        song.save
      end
      artists.each do |artist|
        artist.month_counter = 0
        artist.save
      end
    end
    # reset the year counter at the end of the year
    if today == Date.today.end_of_year
      songs.each do |song|
        song.year_counter = 0
        song.save
      end
      artists.each do |artist|
        artist.year_counter = 0
        artist.save
      end
    end
  end

  def self.today_played_songs
    where("created_at > ?", 1.day.ago).order(created_at: :DESC)
  end

  def self.top_songs
    Song.all.order(total_counter: :DESC)
  end

  def self.top_artists
    Artist.all.order(total_counter: :DESC)
  end

  def autocomplete
    autocomplete.try(:fullname)
  end

  def autocomplete=(fullname)
    self.autocomplete = Song.find_by_fullname(fullname, include: :id) if fullname.present?
  end

  # Methode for destoring all the records in the Generalplaylist model
  def self.destroy_all
    generalplaylists = Generalplaylist.all
    generalplaylists.each do |generalplaylist|
      generalplaylist.destroy
    end
  end

end
