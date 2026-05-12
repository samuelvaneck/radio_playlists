# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::ArrowApiProcessor, type: :service do
  describe '#last_played_song' do
    subject(:last_played_song) { arrow_api_processor.last_played_song }

    let(:arrow_api_processor) { described_class.new(radio_station) }
    let(:radio_station) do
      RadioStation.find_by(name: 'Arrow Classic Rock').presence || create(:arrow_classic_rock)
    end
    let(:response) do
      {
        'title' => 'FAIRIES WEAR BOOTS',
        'artist' => 'BLACK SABBATH',
        'timestamp' => 1_772_788_567,
        'hasCurrentTrack' => true,
        'state' => 'music'
      }
    end

    before do
      allow(arrow_api_processor).to receive(:make_request).and_return(api_response)
    end

    context 'when the API response is valid' do
      let(:api_response) { response }

      it 'sets the artist name' do
        last_played_song
        expect(arrow_api_processor.instance_variable_get(:@artist_name)).to eq('Black Sabbath')
      end

      it 'sets the title' do
        last_played_song
        expect(arrow_api_processor.instance_variable_get(:@title)).to eq('Fairies Wear Boots')
      end

      it 'sets the broadcasted_at timestamp' do
        last_played_song
        expect(arrow_api_processor.instance_variable_get(:@broadcasted_at)).to eq(Time.zone.at(1_772_788_567))
      end

      it 'returns true' do
        expect(last_played_song).to be true
      end
    end

    context 'when the current track is a commercial' do
      let(:api_response) do
        {
          'title' => 'ARROW C R - COMMERCIALS',
          'artist' => '',
          'timestamp' => 1_772_788_355,
          'hasCurrentTrack' => false,
          'state' => 'commercial'
        }
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when the current track has no artist' do
      let(:api_response) do
        {
          'title' => 'UNKNOWN TRACK',
          'artist' => '',
          'timestamp' => 1_772_788_355,
          'hasCurrentTrack' => true,
          'state' => 'music'
        }
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when the API response is blank' do
      let(:api_response) { nil }

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end
  end
end
