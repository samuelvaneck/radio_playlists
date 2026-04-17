# frozen_string_literal: true

class Api::V1::Admins::RadioStationsController < ApplicationController
  def index
    radio_stations = RadioStation.order(:name)
    render json: RadioStationSerializer.new(radio_stations).serializable_hash, status: :ok
  end
end
