# frozen_string_literal: true

class ArtistsController < ApplicationController
  before_action :set_artist, only: %i[show graph_data]
  def index
    artists = Artist.most_played(params)
    @artists = artists.paginate(page: params[:page], per_page: 24)
    render json: ArtistSerializer.new(@artists).serializable_hash.merge(pagination_data).to_json
  end

  def show
    render json: ArtistSerializer.new(@artist).serializable_hash.to_json
  end

  def graph_data
    render json: @artist.graph_data(params[:time] || params[:start_time])
  end

  private

  def set_artist
    @artist = Artist.find params[:id]
  end

  def pagination_data
    return {} if @artists.blank?

    { total_entries: @artists.total_entries || 0, total_pages: @artists.total_pages || 0, current_page: @artists.current_page }
  end
end
