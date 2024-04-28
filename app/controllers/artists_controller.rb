# frozen_string_literal: true

class ArtistsController < ApplicationController
  before_action :set_artist, only: %i[show graph_data]
  def index
    artists = Artist.most_played(params)
    @artists = artists.paginate(page: params[:page], per_page: 24)

    respond_to do |format|
      format.turbo_stream do
        if params[:page].present?
          render turbo_stream: [
            turbo_stream.append('tab-artists', partial: 'artists/index', locals: { params: })
          ]
        else
          render turbo_stream: [
            turbo_stream.update('tab-artists', partial: 'artists/index', locals: { params: }),
            turbo_stream.replace('view-button', partial: 'home/view_buttons/view_button', locals: { params: })
          ]
        end
      end

      format.json { render json: ArtistSerializer.new(@artists).serializable_hash.to_json }
    end

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
