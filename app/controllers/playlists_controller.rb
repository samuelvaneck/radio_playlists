# frozen_string_literal: true

class PlaylistsController < ApplicationController
  def index
    @playlists = playlists.paginate(page: params[:page], per_page: 24)

    pp @playlists

    if params[:page].present?
      render turbo_stream: [
        turbo_stream.append('tab-playlists', partial: 'playlists/index', locals: { params: })
      ]
    else
      render turbo_stream: [
        turbo_stream.update('tab-playlists', partial: 'playlists/index', locals: { params: }),
        turbo_stream.replace('view-button', partial: 'home/view_buttons/view_button', locals: { params: })
      ]
    end
  end

  private

  def playlists
    Playlist.last_played(params)
  end
end
