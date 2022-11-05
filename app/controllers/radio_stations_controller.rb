# frozen_string_literal: true

class RadioStationsController < ApplicationController
  before_action :set_radio_station, except: %i[index]

  def index
    radio_stations = RadioStation.all
    render json: RadioStationSerializer.new(radio_stations).serializable_hash.to_json
  end

  def show
    render json: RadioStationSerializer.new(@radio_station).serializable_hash.to_json
  end

  def status
    respond_with @radio_station.status_data
  end

  private

  def set_radio_station
    @radio_station = RadioStation.find params[:id]
  end
end
