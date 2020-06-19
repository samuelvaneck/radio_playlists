# frozen_string_literal: true

class ArtistsController < ApplicationController
  def index
    artists = Artist.search(params)
    artists = Artist.group_and_count(artists, params)
    render json: artists.paginate(page: params[:page], per_page: 10).to_json
  end

  def show
    artist = Artist.find params[:id]
    options = {}
    options[:include] = [:songs]
    render json: ArtistSerializer.new(artist).serializable_hash.to_json
  end
end
