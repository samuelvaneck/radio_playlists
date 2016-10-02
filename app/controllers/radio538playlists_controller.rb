class Radio538playlistsController < ApplicationController

  def index
    if params[:search].present?
      @radio538playlists = Radio538playlist.where("fullname ILIKE ?", "%#{params[:search]}%").paginate(page: params[:page]).per_page(25)
    else
      @radio538playlists = Radio538playlist.order(total_counter: :desc).paginate(page: params[:page]).per_page(25)
    end
  end

end
