# frozen_string_literal: true

module GraphConcern
  extend ActiveSupport::Concern

  included do
    def graph_data_series(playlists, min_date, max_date)
      min_date.to_date.upto(max_date.to_date).map do |date|
        date = date.strftime('%Y-%m-%d')
        result = { date: }
        grouped_playlists = playlists[date]

        Radiostation.find_each do |radio_station|
          result[radio_station.name] = if grouped_playlists && grouped_playlists[radio_station.id]
                                         grouped_playlists[radio_station.id].count
                                       else
                                         0
                                       end
        end
        result
      end
    end
  end
end
