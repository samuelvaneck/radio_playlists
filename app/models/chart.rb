# frozen_string_literal: true

# == Schema Information
#
# Table name: charts
#
#  id                 :bigint           not null, primary key
#  date               :datetime
#  chart              :jsonb
#  chart_type         :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  chart_positions_id :bigint
#

class Chart < ApplicationRecord
  has_many :chart_positions, dependent: :destroy

  validates :date, :chart_type, presence: true

  scope :songs_charts, -> { where(chart_type: 'songs') }
  scope :artists_charts, -> { where(chart_type: 'artists') }

  def self.create_yesterday_charts
    create_yesterday_chart('songs')
    create_yesterday_chart('artists')
  end

  def self.create_yesterday_chart(chart_type)
    chart = Chart.new(date: 1.day.ago.beginning_of_day, chart_type:)
    chart.__send__("yesterday_#{chart_type}_chart".to_sym).each_with_index do |chart_item, i|
      position = chart.chart_positions.build
      position.positianable = chart_item
      position.position = i + 1
      position.save!
    end

    chart.save!
  end

  def self.latest_song_chart
    Chart.where('created_at > ?', Time.zone.now.beginning_of_day).where(chart_type: 'songs')[0]
  end

  def self.latest_artist_chart
    Chart.where('created_at > ?', Time.zone.now.beginning_of_day).where(chart_type: 'artists')[0]
  end

  def position(object_id)
    chart_index = chart.map.with_index { |idx, i| return i if idx[0] == Integer(object_id, 10) }.compact
    chart_index.blank? ? -1 : chart_index[0]
  end

  private

  def yesterday_songs_chart
    Song.most_played({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
  end

  def yesterday_artists_chart
    Artist.most_played({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
  end

  def yesterday_beginning_of_day
    1.day.ago.beginning_of_day.strftime('%FT%R')
  end

  def yesterday_end_of_day
    1.day.ago.end_of_day.strftime('%FT%R')
  end
end
