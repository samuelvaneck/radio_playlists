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
    index = 1
    chart.__send__("yesterday_#{chart_type}_chart".to_sym).each do |counter, chart_items|
      chart_items.each do |chart_item|
        position = chart.chart_positions.build
        position.positianable = chart_item
        position.counts = counter
        position.position = index
        position.save!
      end
      index += 1
    end

    chart.save!
  end

  def self.latest_song_chart
    Chart.where('created_at > ?', Time.zone.now.beginning_of_day).where(chart_type: 'songs')[0]
  end

  def self.latest_artist_chart
    Chart.where('created_at > ?', Time.zone.now.beginning_of_day).where(chart_type: 'artists')[0]
  end

  def self.recreate_last_year_charts
    (Date.parse('2024-01-01')..Date.parse('2024-11-03')).each do |date|
      [Song, Artist].each do |chart_type|
        chart = Chart.new(date: date, chart_type:)
        index = 1
        start_time = (date - 1).beginning_of_day.strftime('%FT%R')
        end_time = (date -1).end_of_day.strftime('%FT%R')
        chart_type.most_played_group_by(:counter, start_time: , end_time:).each do |counter, chart_items|
          chart_items.each do |chart_item|
            position = chart.chart_positions.build
            position.positianable = chart_item
            position.counts = counter
            position.position = index
            position.save!
          end
          index += 1
        end

        chart.save!
      end
    end
  end

  private

  def yesterday_songs_chart
    Song.most_played_group_by(:counter,{ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
  end

  def yesterday_artists_chart
    Artist.most_played_group_by({ start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
  end

  def yesterday_beginning_of_day
    1.day.ago.beginning_of_day.strftime('%FT%R')
  end

  def yesterday_end_of_day
    1.day.ago.end_of_day.strftime('%FT%R')
  end
end
