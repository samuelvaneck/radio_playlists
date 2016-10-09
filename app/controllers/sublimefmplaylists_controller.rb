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

  def sort_today
    @sublimefmplaylists = Sublimefmplaylist.sort_today.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Sublimefmplaylist.uniq_tracks_day
    @uniq_tracks_week = Sublimefmplaylist.uniq_tracks_week
    @uniq_tracks_month = Sublimefmplaylist.uniq_tracks_month
    @uniq_tracks_year = Sublimefmplaylist.uniq_tracks_year
  end

  def sort_week
    @sublimefmplaylists = Sublimefmplaylist.sort_week.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Sublimefmplaylist.uniq_tracks_day
    @uniq_tracks_week = Sublimefmplaylist.uniq_tracks_week
    @uniq_tracks_month = Sublimefmplaylist.uniq_tracks_month
    @uniq_tracks_year = Sublimefmplaylist.uniq_tracks_year
  end

  def sort_month
    @sublimefmplaylists = Sublimefmplaylist.sort_month.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Sublimefmplaylist.uniq_tracks_day
    @uniq_tracks_week = Sublimefmplaylist.uniq_tracks_week
    @uniq_tracks_month = Sublimefmplaylist.uniq_tracks_month
    @uniq_tracks_year = Sublimefmplaylist.uniq_tracks_year
  end

  def sort_year
    @sublimefmplaylists = Sublimefmplaylist.sort_year.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Sublimefmplaylist.uniq_tracks_day
    @uniq_tracks_week = Sublimefmplaylist.uniq_tracks_week
    @uniq_tracks_month = Sublimefmplaylist.uniq_tracks_month
    @uniq_tracks_year = Sublimefmplaylist.uniq_tracks_year
  end

  def sort_total
    @sublimefmplaylists = Sublimefmplaylist.sort_total.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Sublimefmplaylist.uniq_tracks_day
    @uniq_tracks_week = Sublimefmplaylist.uniq_tracks_week
    @uniq_tracks_month = Sublimefmplaylist.uniq_tracks_month
    @uniq_tracks_year = Sublimefmplaylist.uniq_tracks_year
  end

  def sort_created
    @sublimefmplaylists = Sublimefmplaylist.sort_created.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Sublimefmplaylist.uniq_tracks_day
    @uniq_tracks_week = Sublimefmplaylist.uniq_tracks_week
    @uniq_tracks_month = Sublimefmplaylist.uniq_tracks_month
    @uniq_tracks_year = Sublimefmplaylist.uniq_tracks_year
  end

  def sort_updated
    @sublimefmplaylists = Sublimefmplaylist.sort_updated.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Sublimefmplaylist.uniq_tracks_day
    @uniq_tracks_week = Sublimefmplaylist.uniq_tracks_week
    @uniq_tracks_month = Sublimefmplaylist.uniq_tracks_month
    @uniq_tracks_year = Sublimefmplaylist.uniq_tracks_year
  end

end
