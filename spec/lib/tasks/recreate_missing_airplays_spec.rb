# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'data_repair:recreate_missing_airplays' do # rubocop:disable RSpec/DescribeClass
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    Rails.application.load_tasks
  end

  after do
    Rake::Task['data_repair:recreate_missing_airplays'].reenable
  end

  let(:station) { create(:decibel) }
  let(:broadcasted_at) { 2.hours.ago.change(usec: 0) }

  context 'when no station name is provided' do
    it 'prints usage instructions' do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke }
        .to output(/Usage:/).to_stdout
    end
  end

  context 'when station name does not match any station' do
    it 'prints not found message' do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke('Nonexistent Radio') }
        .to output(/No radio station found/).to_stdout
    end
  end

  context 'when radio_station_songs have no matching airplays' do
    let!(:song1) { create(:song) }
    let!(:song2) { create(:song) }

    before do
      create(:radio_station_song, radio_station: station, song: song1, first_broadcasted_at: broadcasted_at)
      create(:radio_station_song, radio_station: station, song: song2, first_broadcasted_at: broadcasted_at - 1.hour)
    end

    it 'creates airplays for each orphaned radio_station_song', :aggregate_failures do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke('Decibel') }
        .to change(AirPlay, :count).by(2)

      airplay1 = AirPlay.find_by(song: song1, radio_station: station)
      expect(airplay1.broadcasted_at).to eq(broadcasted_at)
      expect(airplay1).to be_confirmed
      expect(airplay1.scraper_import).to be(true)
    end
  end

  context 'when all radio_station_songs already have airplays' do
    let!(:song) { create(:song) }

    before do
      create(:radio_station_song, radio_station: station, song: song, first_broadcasted_at: broadcasted_at)
      create(:air_play, radio_station: station, song: song, broadcasted_at: broadcasted_at)
    end

    it 'does not create any airplays' do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke('Decibel') }
        .not_to change(AirPlay, :count)
    end

    it 'reports nothing to do' do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke('Decibel') }
        .to output(/No radio_station_songs without airplays found/).to_stdout
    end
  end

  context 'when radio_station_song has nil first_broadcasted_at' do
    let!(:song) { create(:song) }

    before do
      create(:radio_station_song, radio_station: station, song: song, first_broadcasted_at: nil)
    end

    it 'skips records without a timestamp' do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke('Decibel') }
        .not_to change(AirPlay, :count)
    end
  end

  context 'when a duplicate airplay already exists for the same broadcasted_at' do
    let!(:song) { create(:song) }

    before do
      create(:radio_station_song, radio_station: station, song: song, first_broadcasted_at: broadcasted_at)
      # Airplay exists for a different station but same song — radio_station_song query should still find it orphaned
      other_station = create(:radio_station)
      create(:air_play, radio_station: other_station, song: song, broadcasted_at: broadcasted_at)
    end

    it 'creates the airplay for the correct station' do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke('Decibel') }
        .to change(AirPlay, :count).by(1)
    end
  end

  context 'when station name is a partial match' do
    before do
      station # ensure created
      song = create(:song)
      create(:radio_station_song, radio_station: station, song: song, first_broadcasted_at: broadcasted_at)
    end

    it 'finds the station by partial name' do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke('decibel') }
        .to change(AirPlay, :count).by(1)
    end
  end

  context 'when some radio_station_songs have airplays and some do not' do
    let!(:song_with_airplay) { create(:song) }
    let!(:song_without_airplay) { create(:song) }

    before do
      create(:radio_station_song, radio_station: station, song: song_with_airplay, first_broadcasted_at: broadcasted_at)
      create(:air_play, radio_station: station, song: song_with_airplay, broadcasted_at: broadcasted_at)
      create(:radio_station_song, radio_station: station, song: song_without_airplay, first_broadcasted_at: broadcasted_at - 30.minutes)
    end

    it 'only creates airplays for the missing ones' do
      expect { Rake::Task['data_repair:recreate_missing_airplays'].invoke('Decibel') }
        .to change(AirPlay, :count).by(1)

      expect(AirPlay.where(song: song_without_airplay, radio_station: station).count).to eq(1)
    end
  end
end
