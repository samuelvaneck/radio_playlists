# frozen_string_literal: true

class SongsController < ApplicationController
  before_action :song, only: %i[show graph_data]

  def index
    songs = Song.most_played(params)
    @songs = songs.paginate(page: params[:page], per_page: 24)

    render json: SongSerializer.new(@songs).serializable_hash.merge(pagination_data).to_json
  end

  def show
    render json: SongSerializer.new(@song).serializable_hash.to_json
  end

  def graph_data
    render json: @song.graph_data(params[:time] || params[:start_time])
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
