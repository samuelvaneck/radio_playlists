# frozen_string_literal: true

class PlaylistsController < ApplicationController
  def index
    @playlists = playlists.paginate(page: params[:page], per_page: 24)

    respond_to do |format|
      format.turbo_stream do
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

      format.json { render json: PlaylistSerializer.new(@playlists).serializable_hash.to_json }
    end
  end

  private

  def playlists
    Playlist.last_played(params)
  end
end
