# frozen_string_literal: true

class SongsController < ApplicationController
  def index
    songs = Song.search(params)
    songs = Song.group_and_count(songs)

    render json: songs.paginate(page: params[:page], per_page: 10).to_json
  end

  def show
    song = Song.find params[:id]
    render json: SongSerializer.new(song).serializable_hash.to_json
  end
end
