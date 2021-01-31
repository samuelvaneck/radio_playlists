# frozen_string_literal: true

class RadiostationsController < ApplicationController
  before_action :set_radiostation, except: %i[index]

  def index
    radiostations = Radiostation.all
    render json: RadiostationSerializer.new(radiostations).serializable_hash.to_json
  end

  def show
    render json: RadiostationSerializer.new(@radio_station).serializable_hash.to_json
  end

  def status
    respond_with @radio_station.mail_data
  end

  private

  def set_radiostation
    @radio_station = Radiostation.find params[:id]
  end
end
