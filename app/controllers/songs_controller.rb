# frozen_string_literal: true

class SongsController < ApplicationController
  def index
    if params[:search_term].present? && params[:radiostation_id].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      @songs_counter = Generalplaylist.joins(:song)
                                      .where('radiostation_id = ? AND songs.fullname ILIKE ?', radiostation.id, "%#{params[:search_term]}%")
                                      .group(:song_id)
                                      .count
                                      .sort_by { |_song_id, counter| counter}
                                      .reverse
    elsif params[:search_term].present?
      @songs_counter = Generalplaylist.joins(:song)
                                      .where('songs.fullname ILIKE ?', "%#{params[:search_term]}%")
                                      .group(:song_id)
                                      .count
                                      .sort_by { |_song_id, counter| counter }
                                      .reverse
    elsif params[:radiostation_id].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      @songs_counter = Generalplaylist.where('radiostation_id = ?', radiostation.id)
                                      .group(:song_id)
                                      .count
                                      .sort_by { |_song_id, counter| counter }
                                      .reverse
    else
      @songs_counter = Generalplaylist.group(:song_id)
                                      .count
                                      .sort_by { |_song_id, counter| counter }
                                      .reverse
    end

    render json: @songs_counter.paginate(page: params[:page], per_page: 10).to_json
  end

  def show
    song = Song.find params[:id]
    render json: SongSerializer.new(song).serializable_hash.to_json
  end
end
