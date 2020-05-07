# frozen_string_literal: true

class ArtistsController < ApplicationController
  def index
    if params[:search_term].present? && params[:radiostation_id].present?
      @artists_counter = Generalplaylist.joins(:artist)
                                        .where('radiostation_id = ? AND artists.name ILIKE ?', params[:radiostation_id], "%#{params[:search_term]}%")
                                        .group(:artist_id)
                                        .count
                                        .sort_by { |_song_id, counter| counter }
                                        .reverse
    elsif params[:search_term].present?
      @artists_counter = Generalplaylist.joins(:artist)
                                        .where('artists.name ILIKE ?', "%#{params[:search_term]}%")
                                        .group(:artist_id)
                                        .count
                                        .sort_by { |_artist_id, counter| counter }
                                        .reverse
    elsif params[:radiostation_id].present?
      @artists_counter = Generalplaylist.where('radiostation_id = ?', params[:radiostation_id])
                                        .group(:artist_id)
                                        .count
                                        .sort_by { |_artist_id, counter| counter }
                                        .reverse
    else
      @artists_counter = Generalplaylist.group(:artist_id)
                                        .count
                                        .sort_by { |_artist_id, counter| counter }
                                        .reverse
    end

    render json: @artists_counter.paginate(page: params[:page], per_page: 10).to_json
  end

  def show
    artist = Artist.find params[:id]
    options = {}
    options[:include] = [:songs]
    render json: ArtistSerializer.new(artist).serializable_hash.to_json
  end
end
