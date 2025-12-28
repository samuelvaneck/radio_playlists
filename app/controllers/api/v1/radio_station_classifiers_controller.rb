# frozen_string_literal: true

module Api
  module V1
    class RadioStationClassifiersController < ApiController
      def index
        classifiers = RadioStationClassifier.includes(:radio_station)
        classifiers = classifiers.where(radio_station_id: params[:radio_station_id]) if params[:radio_station_id].present?
        classifiers = classifiers.where(day_part: params[:day_part]) if params[:day_part].present?

        render json: RadioStationClassifierSerializer.serializable_hash_with_descriptions(classifiers).to_json
      end

      def descriptions
        render json: { data: RadioStationClassifier.attribute_descriptions }.to_json
      end
    end
  end
end
