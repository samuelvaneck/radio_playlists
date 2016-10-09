class SublimefmplaylistsController < ApplicationController

  def index
    if params[:search_fullname].present?
      @sublimefmplaylists = Sublimefmplaylist.where("fullname ILIKE ?", "%#{params[:search_fullname]}%").paginate(page: params[:page]).per_page(10)
    else
      @sublimefmplaylists = Sublimefmplaylist.order(updated_at: :desc).paginate(page: params[:page]).per_page(10)
    end
    @uniq_tracks_day = Sublimefmplaylist.uniq_tracks_day
    @uniq_tracks_week = Sublimefmplaylist.uniq_tracks_week
    @uniq_tracks_month = Sublimefmplaylist.uniq_tracks_month
    @uniq_tracks_year = Sublimefmplaylist.uniq_tracks_year
  end

  def autocomplete
    @results = Sublimefmplaylist.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

end
