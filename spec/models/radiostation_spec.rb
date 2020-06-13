# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Radiostation do
  let(:radio_station) { FactoryBot.create :radiostation }
  let(:playlist_2_hours_ago) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station, created_at: 2.hours.ago }
  let(:playlist_1_minute_ago) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station, created_at: 1.minute.ago }

  describe '#status' do
    context 'with a last playlist created 2 hours ago' do
      it 'has status warning' do
        playlist_2_hours_ago
        status = radio_station.status

        expect(status[:status]).to eq 'Warning'
      end
    end

    context 'with a last playlist created 1 minute ago' do
      it 'has status OK' do
        playlist_1_minute_ago
        status = radio_station.status

        expect(status[:status]).to eq 'OK'
      end
    end

    it 'has the last created time' do
      playlist_1_minute_ago
      status = radio_station.status

      expect(status[:last_created_at].strftime('%H:%M:%S')).to eq playlist_1_minute_ago.created_at.strftime('%H:%M:%S')
    end

    it 'has the track info' do
      playlist_1_minute_ago
      status = radio_station.status

      expect(status[:track_info]).to eq "#{playlist_1_minute_ago.time} - #{playlist_1_minute_ago.artists.map(&:name).join(' - ')} - #{playlist_1_minute_ago.song.title}"
    end
  end
end
