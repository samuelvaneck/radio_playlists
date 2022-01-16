# frozen_string_literal: true

class ArtistsController < ApplicationController
  def index
    artists = Artist.search(params)
    artists = Artist.group_and_count(artists)
    artists = paginate_and_serialize(artists)
    render json: artists
  end

  def show
    artist = Artist.find params[:id]
    options = {}
    options[:include] = [:songs]
    render json: ArtistSerializer.new(artist).serializable_hash.to_json
  end

  private

  def paginate_and_serialize(artists)
    artists.paginate(page: params[:page], per_page: 10)
            .map do |artist_id, counter|
              serialized_artist = ArtistSerializer.new(Artist.find(artist_id)).serializable_hash
              [serialized_artist, counter]
            end
  end
end
