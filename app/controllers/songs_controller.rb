# frozen_string_literal: true

class SongsController < ApplicationController
  before_action :song, only: %i[show graph_data]

  def index
    songs = Song.most_played(params)
    @songs = songs.paginate(page: params[:page], per_page: 24)

    respond_to do |format|
      format.turbo_stream do
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

      format.json { render json: SongSerializer.new(@songs).serializable_hash.merge(pagination_data).to_json }
    end
  end

  def show
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('graph-title', partial: 'songs/graph_title', locals: { song: @song })
        ]
      end

      format.json { render json: SongSerializer.new(@song).serializable_hash.to_json }
    end
  end

  def graph_data
    render json: @song.graph_data(params[:time])
  end

  private

  def song
    @song = Song.find params[:id]
  end

  def pagination_data
    return {} if @songs.blank?

    { total_entries: @songs.total_entries || 0, total_pages: @songs.total_pages || 0, current_page: @songs.current_page }
  end
end
