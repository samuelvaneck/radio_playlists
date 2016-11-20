class GeneralplaylistsController < ApplicationController

  def index
    @generalplaylists = Generalplaylist.all
  end

end
