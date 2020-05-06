# frozen_string_literal: true

class RadiostationsController < ApplicationController
  def index
    radiostations = Radiostation.all
    render json: RadiostationSerializer.new(radiostations).serializable_hash.to_json
  end

  def show
    radio_station = Radiostation.find params[:id]
    render json: RadiostationSerializer.new(radio_station).serializable_hash.to_json
  end
end
