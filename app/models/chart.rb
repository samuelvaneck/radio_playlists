# frozen_string_literal: true

# == Schema Information
#
# Table name: charts
#
#  id         :bigint           not null, primary key
#  date       :date
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
      # reorder chart items by the number of playlists they were played in the last month
      chart_items = chart_items.sort_by do |item|
        -item.playlists.where('broadcasted_at >= ? AND broadcasted_at <= ?', 1.week.ago, 1.day.ago.end_of_day.strftime('%FT%R')).count
      end

      chart_items.each do |chart_item|
        position = chart.chart_positions.build
        position.positianable = chart_item
        position.counts = counter
        position.position = index
        position.save!
        UpdateItemChartPositionsJob.perform_async(item_id: chart_item.id, item_type: chart_type)
        index += 1
      end
    end

    chart.save!
  end

  def self.latest_song_chart
    Chart.where('created_at > ?', Time.zone.now.beginning_of_day).where(chart_type: 'songs')[0]
  end

  def self.latest_artist_chart
    Chart.where('created_at > ?', Time.zone.now.beginning_of_day).where(chart_type: 'artists')[0]
  end

  def self.recreate_past_charts
    (Date.parse('2021-01-17')..Date.today).each do |date|
      [Song, Artist].each do |chart_type|
        chart = Chart.new(date: date, chart_type:)
        index = 1
        start_time = (date - 1).beginning_of_day
        end_time = (date -1).end_of_day.strftime('%FT%R')
        chart_type.most_played_group_by(:counter, start_time: start_time.strftime('%FT%R'), end_time:).each do |counter, chart_items|
          # reorder chart items by the number of playlists they were played in the last month
          chart_items = chart_items.sort_by do |item|
            -item.playlists.where('broadcasted_at >= ? AND broadcasted_at <= ?', (start_time - 1.week), end_time).count
          end

          chart_items.each do |chart_item|
            position = chart.chart_positions.build
            position.positianable = chart_item
            position.counts = counter
            position.position = index
            position.save!
            index += 1
          end
        end

        chart.save!
      end
    end
  end

  private

  def yesterday_songs_chart
    Song.most_played_group_by(:counter, { start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
  end

  def yesterday_artists_chart
    Artist.most_played_group_by(:counter, { start_time: yesterday_beginning_of_day, end_time: yesterday_end_of_day })
  end

  def yesterday_beginning_of_day
    1.day.ago.beginning_of_day.strftime('%FT%R')
  end

  def yesterday_end_of_day
    1.day.ago.end_of_day.strftime('%FT%R')
  end
end
