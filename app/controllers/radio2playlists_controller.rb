class Radio2playlistsController < ApplicationController

  def index
    if params[:search_fullname].present?
      @radio2playlists = Radio2playlist.where("fullname ILIKE ?", "%#{params[:search_fullname]}%").paginate(page: params[:page]).per_page(10)
    else
      @radio2playlists = Radio2playlist.order(updated_at: :desc).paginate(page: params[:page]).per_page(10)
    end
    @uniq_tracks_day = Radio2playlist.uniq_tracks_day
    @uniq_tracks_week = Radio2playlist.uniq_tracks_week
    @uniq_tracks_month = Radio2playlist.uniq_tracks_month
    @uniq_tracks_year = Radio2playlist.uniq_tracks_year
  end

  def autocomplete
    @results = Radio2playlist.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

end
