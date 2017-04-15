class GeneralplaylistsController < ApplicationController

  def index
    if params[:search_top_song].present?
      @top_songs = Song.where("title ILIKE ?", "%#{params[:search_top_song]}%").limit(3)
    else
      @top_songs = Song.order(week_counter: :DESC).limit(3)
    end

    if params[:search_top_artist].present?
      @top_artists = Artist.where("name ILIKE ?", "%#{params[:search_top_artist]}%").limit(3)
    else
      @top_artists = Artist.order(week_counter: :DESC).limit(3)
    end

    @target = params[:target]
  end

  def song_details
    @details = Song.where("fullname ILIKE ?", "%#{params[:search_fullname]}%")
  end

  def today_played_songs
    @today_played_songs = Generalplaylist.today_played_songs.paginate(page: params[:page]).per_page(10)
  end

  def top_songs
    if params[:page].present?
      @counter = (params[:page].to_i * 10) -10
    else
      @counter = 0
    end
    @top_songs = Generalplaylist.top_songs.paginate(page: params[:page]).per_page(10)
  end

  def top_artists
    if params[:page].present?
      @counter = (params[:page].to_i * 10) -10
    else
      @counter = 0
    end
    @top_artists = Generalplaylist.top_artists.paginate(page: params[:page]).per_page(10)
  end

  def autocomplete
    @results = Song.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

end
