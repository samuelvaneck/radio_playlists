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

  def chart_postion(id, type); end

  private

  def yesterdays_songs_chart
    songs = Song.search({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
    Song.group_and_count(songs)
  end

  def yesterdays_artists_chart
    artists = Artist.search({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
    Artist.group_and_count(artists)
  end

  def song_position(song_id); end

  def artist_position(artist_id); end

  def yesterday_beginning_of_day
    1.day.ago.beginning_of_day.strftime('%FT%R')
  end

  def yesterday_end_of_day
    1.day.ago.end_of_day.strftime('%FT%R')
  end
end
