# frozen_string_literal: true

class Api::V1::Admins::SongsController < ApplicationController
  def index
    songs = Song.includes(:artists)
              .search(params[:search_term])
              .order(created_at: :desc)
              .paginate(page: params[:page], per_page: params[:per_page] || 24)
    render json: SongSerializer.new(songs).serializable_hash, status: :ok
  end

  def update
    song = Song.find(params[:id])
    if song.update(song_update_attributes)
      render json: SongSerializer.new(song).serializable_hash, status: :ok
    else
      render json: { errors: song.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def song_update_attributes
    attributes = song_params
    attributes[:id_on_youtube] = Youtube::IdExtractor.extract(attributes[:id_on_youtube]) if attributes.key?(:id_on_youtube)
    attributes
  end

  def song_params
    params.require(:song).permit(:id_on_youtube)
  rescue ActionController::ParameterMissing
    {}
  end
end
