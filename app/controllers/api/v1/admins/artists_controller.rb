# frozen_string_literal: true

class Api::V1::Admins::ArtistsController < ApplicationController
  def index
    artists = Artist.includes(:songs)
                    .matching(params[:search_term])
                    .order(created_at: :desc)
                    .paginate(page: params[:page], per_page: params[:per_page] || 24)
    render json: ArtistSerializer.new(artists).serializable_hash, status: :ok
  end

  def update
    artist = Artist.find(params[:id])
    if artist.update(artist_params)
      render json: ArtistSerializer.new(artist).serializable_hash, status: :ok
    else
      render json: { errors: artist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def artist_params
    params.require(:artist).permit(:website_url, :instagram_url)
  rescue ActionController::ParameterMissing
    {}
  end
end
