class GrootnieuwsplaylistsController < ApplicationController

  def index
    if params[:search_fullname].present?
      @grootnieuwsplaylists = Grootnieuwsplaylist.where("fullname ILIKE ?", "%#{params[:search_fullname]}%").paginate(page: params[:page]).per_page(10)
    else
      @grootnieuwsplaylists = Grootnieuwsplaylist.order(updated_at: :desc).paginate(page: params[:page]).per_page(10)
    end
    @uniq_tracks_day = Grootnieuwsplaylist.uniq_tracks_day
    @uniq_tracks_week = Grootnieuwsplaylist.uniq_tracks_week
    @uniq_tracks_month = Grootnieuwsplaylist.uniq_tracks_month
    @uniq_tracks_year = Grootnieuwsplaylist.uniq_tracks_year
  end

  def autocomplete
    @results = Grootnieuwsplaylist.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

  def sort_today
    @grootnieuwsplaylists = Grootnieuwsplaylist.sort_today.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Grootnieuwsplaylist.uniq_tracks_day
    @uniq_tracks_week = Grootnieuwsplaylist.uniq_tracks_week
    @uniq_tracks_month = Grootnieuwsplaylist.uniq_tracks_month
    @uniq_tracks_year = Grootnieuwsplaylist.uniq_tracks_year
  end

  def sort_week
    @grootnieuwsplaylists = Grootnieuwsplaylist.sort_week.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Grootnieuwsplaylist.uniq_tracks_day
    @uniq_tracks_week = Grootnieuwsplaylist.uniq_tracks_week
    @uniq_tracks_month = Grootnieuwsplaylist.uniq_tracks_month
    @uniq_tracks_year = Grootnieuwsplaylist.uniq_tracks_year
  end

  def sort_month
    @grootnieuwsplaylists = Grootnieuwsplaylist.sort_month.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Grootnieuwsplaylist.uniq_tracks_day
    @uniq_tracks_week = Grootnieuwsplaylist.uniq_tracks_week
    @uniq_tracks_month = Grootnieuwsplaylist.uniq_tracks_month
    @uniq_tracks_year = Grootnieuwsplaylist.uniq_tracks_year
  end

  def sort_year
    @grootnieuwsplaylists = Grootnieuwsplaylist.sort_year.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Grootnieuwsplaylist.uniq_tracks_day
    @uniq_tracks_week = Grootnieuwsplaylist.uniq_tracks_week
    @uniq_tracks_month = Grootnieuwsplaylist.uniq_tracks_month
    @uniq_tracks_year = Grootnieuwsplaylist.uniq_tracks_year
  end

  def sort_total
    @grootnieuwsplaylists = Grootnieuwsplaylist.sort_total.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Grootnieuwsplaylist.uniq_tracks_day
    @uniq_tracks_week = Grootnieuwsplaylist.uniq_tracks_week
    @uniq_tracks_month = Grootnieuwsplaylist.uniq_tracks_month
    @uniq_tracks_year = Grootnieuwsplaylist.uniq_tracks_year
  end

  def sort_created
    @grootnieuwsplaylists = Grootnieuwsplaylist.sort_created.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Grootnieuwsplaylist.uniq_tracks_day
    @uniq_tracks_week = Grootnieuwsplaylist.uniq_tracks_week
    @uniq_tracks_month = Grootnieuwsplaylist.uniq_tracks_month
    @uniq_tracks_year = Grootnieuwsplaylist.uniq_tracks_year
  end

  def sort_updated
    @grootnieuwsplaylists = Grootnieuwsplaylist.sort_updated.paginate(page: params[:page]).per_page(10)
    @uniq_tracks_day = Grootnieuwsplaylist.uniq_tracks_day
    @uniq_tracks_week = Grootnieuwsplaylist.uniq_tracks_week
    @uniq_tracks_month = Grootnieuwsplaylist.uniq_tracks_month
    @uniq_tracks_year = Grootnieuwsplaylist.uniq_tracks_year
  end

end
