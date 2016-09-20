class PlaylistsController < ApplicationController

  def index
    @playlists = Playlist.order(counter: :desc)
  end

end
