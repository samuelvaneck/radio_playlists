# frozen_string_literal: true

class SongsController < ApplicationController
  def index
    songs = Song.search(params)
    songs = Song.group_and_count(songs)
    songs = paginate_and_serialize(songs)
    render json: songs
  end

  def show
    song = Song.find params[:id]
    render json: SongSerializer.new(song).serializable_hash.to_json
  end

  private

  def paginate_and_serialize(songs)
    songs.paginate(page: params[:page], per_page: 10)
         .map do |song_id, counter|
           serialized_song = SongSerializer.new(Song.find(song_id)).serializable_hash
           [serialized_song, counter]
         end
  end
end
