class PlaylistsController < ApplicationController



  def index
    @playlists = Playlist.order(total_counter: :desc).paginate(page: params[:page]).per_page(25)
  end

end
