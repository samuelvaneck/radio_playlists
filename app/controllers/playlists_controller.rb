class PlaylistsController < ApplicationController

  def index
    if params[:search].present?
      @playlists = Playlist.where("fullname ILIKE ?", "%#{params[:search]}%").paginate(page: params[:page]).per_page(25)
    else
      @playlists = Playlist.order(total_counter: :desc).paginate(page: params[:page]).per_page(25)
    end
  end

end
