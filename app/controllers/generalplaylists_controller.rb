# frozen_string_literal: true

class GeneralplaylistsController < ApplicationController
  respond_to :html, :js

  def index
    playlists = Generalplaylist.search(params)

    respond_with GeneralplaylistSerializer.new(playlists.paginate(:page => params[:page], :per_page => 10)).serializable_hash.to_json
  end
end
