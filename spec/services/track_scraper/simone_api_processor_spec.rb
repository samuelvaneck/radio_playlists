# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::SimoneApiProcessor, type: :service do
  subject(:last_played_song) { processor.last_played_song }

  let(:processor) { described_class.new(radio_station) }
  let(:radio_station) do
    RadioStation.find_by(name: 'Simone FM').presence || create(:simone_fm)
  end
  let(:response) do
    [
      {
        'station' => 'SIMONEFM',
        'artist' => 'Red Hot Chili Peppers',
        'title' => 'Scar tissue',
        'timestamp' => '2026-03-30T09:51:13.124Z'
      }
    ]
  end

  describe '#last_played_song' do
    before do
      allow(processor).to receive(:fetch_playlist).and_return(api_response)
    end

    context 'when the API response is valid' do
      let(:api_response) { response }

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
        expect(processor.broadcasted_at).to eq(Time.zone.parse('2026-03-30T09:51:13.124Z'))
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
  end
end
