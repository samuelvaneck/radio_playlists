# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::SimoneApiProcessor, type: :service do
  subject(:last_played_song) { processor.last_played_song }

  let(:processor) { described_class.new(radio_station) }
  let(:radio_station) do
    RadioStation.find_by(name: 'Simone FM').presence || create(:simone_fm)
  end
  let(:now) { Time.zone.now }
  let(:newest_track) do
    {
      'station' => 'SIMONEFM',
      'artist' => 'Red Hot Chili Peppers',
      'title' => 'Scar tissue',
      'timestamp' => (now - 4.minutes).iso8601(3)
    }
  end
  let(:older_track) do
    {
      'station' => 'SIMONEFM',
      'artist' => 'Foo Fighters',
      'title' => 'Everlong',
      'timestamp' => (now - 8.minutes).iso8601(3)
    }
  end
  let(:oldest_track) do
    {
      'station' => 'SIMONEFM',
      'artist' => 'Pearl Jam',
      'title' => 'Black',
      'timestamp' => (now - 12.minutes).iso8601(3)
    }
  end

  describe '#last_played_song' do
    before do
      allow(processor).to receive(:fetch_playlist).and_return(api_response)
    end

    context 'when the API response is valid' do
      let(:api_response) { [newest_track] }

      it 'returns true' do
        expect(last_played_song).to be true
      end

      it 'sets the artist name' do
        last_played_song
        expect(processor.artist_name).to eq('Red Hot Chili Peppers')
      end

      it 'sets the title' do
        last_played_song
        expect(processor.title).to eq('Scar Tissue')
      end

      it 'sets the broadcasted_at timestamp' do
        last_played_song
        expect(processor.broadcasted_at).to eq(Time.zone.parse(newest_track['timestamp']))
      end

      it 'sets the raw response' do
        last_played_song
        expect(processor.raw_response).to be_present
      end
    end

    context 'when the API response is blank' do
      let(:api_response) { nil }

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when the track is blank' do
      let(:api_response) { [] }

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'with multiple tracks and no prior import logs' do
      let(:api_response) { [newest_track, older_track, oldest_track] }

      it 'picks the newest track so now-playing stays fresh', :aggregate_failures do
        last_played_song
        expect(processor.artist_name).to eq('Red Hot Chili Peppers')
        expect(processor.title).to eq('Scar Tissue')
      end
    end

    context 'with multiple tracks where the newest was already imported' do
      let(:api_response) { [newest_track, older_track, oldest_track] }

      before do
        SongImportLog.create!(
          radio_station: radio_station,
          status: :success,
          import_source: :scraping,
          scraped_artist: 'Red Hot Chili Peppers',
          scraped_title: 'Scar Tissue',
          broadcasted_at: Time.zone.parse(newest_track['timestamp'])
        )
      end

      it 'drains the next-newest unlogged track', :aggregate_failures do
        last_played_song
        expect(processor.artist_name).to eq('Foo Fighters')
        expect(processor.title).to eq('Everlong')
      end
    end

    context 'when every track is already in the import log' do
      let(:api_response) { [newest_track, older_track] }

      before do
        [newest_track, older_track].each do |track|
          SongImportLog.create!(
            radio_station: radio_station,
            status: :success,
            import_source: :scraping,
            scraped_artist: track['artist'].titleize,
            scraped_title: TitleSanitizer.sanitize(track['title']).titleize,
            broadcasted_at: Time.zone.parse(track['timestamp'])
          )
        end
      end

      it 'falls back to the newest track for SongImporter dedupe' do
        last_played_song
        expect(processor.broadcasted_at).to eq(Time.zone.parse(newest_track['timestamp']))
      end
    end

    context 'when older entries fall outside the 1h lookback' do
      let(:stale_track) do
        {
          'station' => 'SIMONEFM',
          'artist' => 'Soundgarden',
          'title' => 'Black hole sun',
          'timestamp' => (now - 2.hours).iso8601(3)
        }
      end
      let(:api_response) { [newest_track, stale_track] }

      it 'ignores tracks older than the cutoff' do
        last_played_song
        expect(processor.broadcasted_at).to eq(Time.zone.parse(newest_track['timestamp']))
      end
    end

    context 'when every entry is outside the 1h lookback' do
      let(:stale_track) do
        {
          'station' => 'SIMONEFM',
          'artist' => 'Soundgarden',
          'title' => 'Black hole sun',
          'timestamp' => (now - 2.hours).iso8601(3)
        }
      end
      let(:api_response) { [stale_track] }

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end
  end
end
