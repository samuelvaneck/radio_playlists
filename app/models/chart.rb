# frozen_string_literal: true

# == Schema Information
#
# Table name: charts
#
#  id         :bigint           not null, primary key
#  date       :datetime
#  chart      :jsonb
#  chart_type :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Chart < ApplicationRecord
  validates :date, :chart, :chart_type, presence: true

  scope :songs_charts, -> { where(chart_type: 'songs') }
  scope :artists_charts, -> { where(chart_type: 'artists') }

  def self.create_yesterdays_charts
    create_yesterdays_chart('songs')
    create_yesterdays_chart('artists')
  end

  def self.create_yesterdays_chart(chart_type)
    chart = Chart.new(date: 1.day.ago.beginning_of_day, chart_type:)
    chart.chart = chart.__send__("yesterdays_#{chart_type}_chart".to_sym)
    chart.save
  end

  def position(object_id)
    chart_index = chart.map.with_index { |idx, i| return i if idx[0] == Integer(object_id, 10) }.compact
    chart_index.blank? ? -1 : chart_index[0]
  end

  private

  def yesterdays_songs_chart
    Song.most_played({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
  end

  def yesterdays_artists_chart
    Artist.most_played({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
  end

  def yesterday_beginning_of_day
    1.day.ago.beginning_of_day.strftime('%FT%R')
  end

  def yesterday_end_of_day
    1.day.ago.end_of_day.strftime('%FT%R')
  end
end
