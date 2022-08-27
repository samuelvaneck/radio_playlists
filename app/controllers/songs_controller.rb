# frozen_string_literal: true

class SongsController < ApplicationController
  before_action :set_song, only: %i[show graph_data]

  def index
    songs = Song.search(params)
    songs = Song.group_and_count(songs)
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
         .map do |song_id, counter|
           serialized_song = SongSerializer.new(Song.find(song_id)).serializable_hash
           [serialized_song, counter]
         end
  end

  def set_song
    @song = Song.find params[:id]
  end
end
