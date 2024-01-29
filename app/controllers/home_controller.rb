class HomeController < ApplicationController
  def index
    @radio_stations = RadioStation.all
    render :index, params: { view: params[:view] }
  end
end
