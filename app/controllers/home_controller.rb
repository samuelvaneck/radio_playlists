class HomeController < ApplicationController
  def index
    @songs = Song.most_played({}).limit(3)
    @radio_stations = RadioStation.all
  end
end
