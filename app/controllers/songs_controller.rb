# frozen_string_literal: true

class SongsController < ApplicationController
  before_action :set_song, only: %i[show graph_data]

  def index
    songs = Song.most_played(params)
    songs = paginate_and_serialize(songs)
    render json: songs
  end

  def show
    render json: SongSerializer.new(@song).serializable_hash.to_json
  end

  def graph_data
    render json: @song.graph_data(params[:time])
  end

  private

  def paginate_and_serialize(songs)
    songs.paginate(page: params[:page], per_page: 10)
         .map do |song|
           serialized_song = SongSerializer.new(song).serializable_hash
           [serialized_song, song.counter]
         end
  end

  def set_song
    @song = Song.find params[:id]
  end
end
