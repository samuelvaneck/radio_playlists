# frozen_string_literal: true

class Chart < ApplicationRecord
  validates :date, :chart, :chart_type, presence: true

  scope :songs_charts, -> { where(chart_type: 'songs') }
  scope :artists_charts, -> { where(chart_type: 'artists') }

  def self.create_yesterdays_charts
    create_yesterdays_chart('songs')
    create_yesterdays_chart('artists')
  end

  def self.create_yesterdays_chart(chart_type)
    chart = Chart.new(date: 1.day.ago.beginning_of_day, chart_type: chart_type)
    chart.chart = chart.__send__("yesterdays_#{chart_type}_chart".to_sym)
    chart.save
  end

  def position(object_id)
    chart_index = chart.map { |idx| return idx[1] if idx[0] == Integer(object_id, 10) }.compact
    chart_index.blank? ? -1 : chart_index[0] + 1
  end

  private

  def yesterdays_songs_chart
    songs = Song.search({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
    Song.group_and_count(songs)
  end

  def yesterdays_artists_chart
    artists = Artist.search({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
    Artist.group_and_count(artists)
  end

  def yesterday_beginning_of_day
    1.day.ago.beginning_of_day.strftime('%FT%R')
  end

  def yesterday_end_of_day
    1.day.ago.end_of_day.strftime('%FT%R')
  end
end
