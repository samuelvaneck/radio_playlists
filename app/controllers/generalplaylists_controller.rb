class GeneralplaylistsController < ApplicationController

  def index
    @generalplaylists = Generalplaylist.order(created_at: :DESC).limit(10)
    @veronicaplaylists = Generalplaylist.where(radiostation_id: '1').order(created_at: :DESC).limit(10)
    @radio538playlists = Generalplaylist.where(radiostation_id: '2').order(created_at: :DESC).limit(10)
    @sublimefmplaylists = Generalplaylist.where(radiostation_id: '3').order(created_at: :DESC).limit(10)
    @radio2playlists = Generalplaylist.where(radiostation_id: '4').order(created_at: :DESC).limit(10)
    @gnrplaylists = Generalplaylist.where(radiostation_id: '5').order(created_at: :DESC).limit(10)
    @top_10_songs_week = Song.order(week_counter: :DESC).limit(10)
    @top_10_artists_week = Artist.order(week_counter: :DESC).limit(10)
    @counter_songs = 0
    @counter_artists = 0
  end

  def song_details
    @details = Song.where("fullname ILIKE ?", "%#{params[:search_fullname]}%")
  end

  def today_played_songs
    @today_played_songs = Generalplaylist.today_played_songs.paginate(page: params[:page]).per_page(10)
  end

  def top_songs
    @top_songs = Generalplaylist.top_songs.paginate(page: params[:page]).per_page(10)
    @counter = 0
  end

  def top_artists
    @top_artists = Generalplaylist.top_artists.paginate(page: params[:page]).per_page(10)
    @counter = 0
  end

  def autocomplete
    @results = Song.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

end
