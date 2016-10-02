class Radio538playlistsController < ApplicationController

  def index
    if params[:search_fullname].present?
      @radio538playlists = Radio538playlist.where("fullname ILIKE ?", "%#{params[:search_fullname]}%").paginate(page: params[:page]).per_page(25)
    else
      @radio538playlists = Radio538playlist.order(total_counter: :desc).paginate(page: params[:page]).per_page(25)
    end
  end

  def autocomplete
    @results = Radio538playlist.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

end
