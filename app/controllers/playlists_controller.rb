class PlaylistsController < ApplicationController

  def index
    if params[:search_fullname].present?
      @playlists = Playlist.where("fullname ILIKE ?", "%#{params[:search_fullname]}%").paginate(page: params[:page]).per_page(25)
    else
      @playlists = Playlist.order(total_counter: :desc).paginate(page: params[:page]).per_page(25)
    end
    @uniq_tracks_day = Playlist.uniq_tracks_day
    @uniq_tracks_week = Playlist.uniq_tracks_week
    @uniq_tracks_month = Playlist.uniq_tracks_month
    @uniq_tracks_year = Playlist.uniq_tracks_year
  end

  def autocomplete
    @results = Playlist.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

end
