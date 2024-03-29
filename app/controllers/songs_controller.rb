# frozen_string_literal: true

class SongsController < ApplicationController
  before_action :set_song, only: %i[show graph_data]

  def index
    songs = Song.most_played(params)
    @songs = songs.paginate(page: params[:page], per_page: 24)

    if params[:page].present?
      render turbo_stream: [
        turbo_stream.append('tab-songs', partial: 'songs/index', locals: { params: })
      ]
    else
      render turbo_stream: [
        turbo_stream.update('tab-songs', partial: 'songs/index', locals: { params: }),
        turbo_stream.replace('view-button', partial: 'home/view_buttons/view_button', locals: { params: })
      ]
    end
  end

  def show
    render turbo_stream: [
      turbo_stream.update('graph-title', partial: 'songs/graph_title', locals: { song: @song })
    ]
  end

  def graph_data
    render json: @song.graph_data(params[:time])
  end

  private

  def set_song
    @song = Song.find params[:id]
  end
end
