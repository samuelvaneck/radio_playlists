class GeneralplaylistsController < ApplicationController

  def index
    @generaplaylists = Generplaylist.all
  end

end
