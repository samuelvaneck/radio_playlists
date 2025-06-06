# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::QmusicApiProcessor, type: :service do
  describe '#last_played_song' do
    subject(:last_played_song) { qmusic_api_processor.last_played_song }

    let(:qmusic_api_processor) { described_class.new(radio_station) }
    let(:radio_station) do
      RadioStation.find_by(name: 'Qmusic') || create(:qmusic)
    end
    let(:response) do
      {
        played_tracks: [
          {
            played_at: '2023-10-01T12:00:00+02:00',
            artist: { name: 'Test Artist' },
            title: 'Test Title',
            spotify_url: 'https://open.spotify.com/track/test',
            videos: [{ id: 'test_youtube_id' }]
          }
        ]
      }
    end

    before do
      allow(qmusic_api_processor).to receive(:make_request).and_return(api_response)
    end

    context 'when the API response is valid' do
      let(:api_response) { response }

      it 'sets the broadcasted_at timestamp' do
        last_played_song
        expect(qmusic_api_processor.instance_variable_get(:@broadcasted_at)).to eq(Time.find_zone('Amsterdam').parse('2023-10-01T12:00:00+02:00'))
      end

      it 'sets the artist name' do
        last_played_song
        expect(qmusic_api_processor.instance_variable_get(:@artist_name)).to eq('Test Artist')
      end

      it 'sets the title' do
        last_played_song
        expect(qmusic_api_processor.instance_variable_get(:@title)).to eq('Test Title')
      end

      it 'sets the Spotify URL' do
        last_played_song
        expect(qmusic_api_processor.instance_variable_get(:@spotify_url)).to eq('https://open.spotify.com/track/test')
      end

      it 'sets the YouTube ID' do
        last_played_song
        expect(qmusic_api_processor.instance_variable_get(:@youtube_id)).to eq('test_youtube_id')
      end

      it 'returns true' do
        expect(last_played_song).to be true
      end
    end

    context 'when the API response is blank' do
      let(:api_response) { nil }

      before do
        allow(Rails.logger).to receive(:info).and_call_original
        allow(ExceptionNotifier).to receive(:notify_new_relic).and_call_original
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end

      it 'notifies New Relic' do
        last_played_song
        expect(ExceptionNotifier).to have_received(:notify_new_relic).with(instance_of(StandardError))
      end

      it 'logs the error' do
        last_played_song
        expect(Rails.logger).to have_received(:info).with(instance_of(String))
      end
    end
  end
end
