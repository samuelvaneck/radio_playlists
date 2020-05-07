# frozen_string_literal: true

class GeneralplaylistsController < ApplicationController
  respond_to :html, :js

  def index
    # Playlist search options
    @playlists = Generalplaylist.order(created_at: :DESC)
    @playlists = @playlists.joins(:artist, :song)
                           .where!('artists.name ILIKE ? OR songs.fullname ILIKE ?', "%#{params[:search_term]}%", "%#{params[:search_term]}%") if params[:search_term].present?
    @playlists = @playlists.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?

    @playlists = @playlists.paginate(page: params[:page], per_page: 10)

    respond_with GeneralplaylistSerializer.new(@playlists).serializable_hash.to_json
  end
end
