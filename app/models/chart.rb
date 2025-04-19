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
  validates :date, uniqueness: { scope: :chart_type, message: 'Chart already exists for this date' }

  scope :songs_charts, -> { where(chart_type: 'songs') }
  scope :artists_charts, -> { where(chart_type: 'artists') }

  def self.create_yesterday_charts
    create_yesterday_chart('songs')
    create_yesterday_chart('artists')
  end

  def self.create_yesterday_chart(chart_type)
    date = 1.day.ago.beginning_of_day
    chart = Chart.create!(date:, chart_type:)

    chart.create_chart_positions
  end

  def self.latest_song_chart
    Chart.where(chart_type: 'songs').order(date: :desc).first
  end

  def self.latest_artist_chart
    Chart.where(chart_type: 'artists').order(date: :desc).first
  end

  def self.recreate_past_charts
    (Date.parse('2021-01-17')..Time.zone.today).each do |date|
      [Song, Artist].each do |chart_type|
        chart = Chart.new(date: date, chart_type:)
        index = 1
        start_time = (date - 1).beginning_of_day
        end_time = (date - 1).end_of_day.strftime('%FT%R')
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

  def create_chart_positions
    index = 1
    __send__("yesterday_#{chart_type}_chart".to_sym).each do |counter, chart_items|
      # reorder chart items by the number of playlists they were played in the last month
      chart_items = chart_items.sort_by do |item|
        -item.playlists.where('broadcasted_at >= ? AND broadcasted_at <= ?', 1.week.ago, 1.day.ago.end_of_day.strftime('%FT%R')).count
      end

      chart_items.each do |chart_item|
        position = chart_positions.build
        position.positianable = chart_item
        position.counts = counter
        position.position = index
        position.save!
        job_args = { item_id: chart_item.id,
                     item_type: chart_type,
                     chart_date: date,
                     chart_position: index,
                     chart_counts: counter }
        UpdateItemChartPositionsJob.perform_async(job_args.to_json)
        index += 1
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
