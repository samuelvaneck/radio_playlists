# frozen_string_literal: true

class PlaylistsController < ApplicationController
  respond_to :html, :js

  def index
    respond_with PlaylistSerializer.new(playlists.paginate(page: params[:page], per_page: 10))
                                   .serializable_hash.to_json
  end

  private

  def playlists
    Playlist.last_played(params)
  end
end
