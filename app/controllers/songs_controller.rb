# frozen_string_literal: true

class SongsController < ApplicationController
  def index
    @songs = Song.all
  end

  def show
    song = Song.find params[:id]
    render json: SongSerializer.new(song).serializable_hash.to_json
  end
end
