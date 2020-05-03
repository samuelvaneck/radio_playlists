# frozen_string_literal: true

class ArtistsController < ApplicationController
  def index
    @artists = Artist.all
  end

  def show
    artist = Artist.find params[:id]
    render json: ArtistSerializer.new(artist).serializable_hash.to_json
  end
end
