# frozen_string_literal: true

class ArtistsController < ApplicationController
  before_action :set_artist, only: %i[show graph_data]
  def index
    artists = Artist.most_played(params)
    artists = paginate_and_serialize(artists)
    render json: artists
  end

  def show
    options = {}
    options[:include] = [:songs]
    render json: ArtistSerializer.new(@artist).serializable_hash.to_json
  end

  def graph_data
    render json: @artist.graph_data(params[:time])
  end

  private

  def paginate_and_serialize(artists)
    artists.paginate(page: params[:page], per_page: 10)
            .map do |artist|
              serialized_artist = ArtistSerializer.new(artist).serializable_hash
              [serialized_artist, artist.counter]
            end
  end

  def set_artist
    @artist = Artist.find params[:id]
  end
end
