class HomeController < ApplicationController
  def index
    @songs = Song.most_played({}).limit(12)
    @radio_stations = RadioStation.all
    render :index, params: { view: params[:view] }
  end
end
