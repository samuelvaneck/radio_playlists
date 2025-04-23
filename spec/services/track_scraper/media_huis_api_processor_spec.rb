# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::MediaHuisApiProcessor, type: :service do
  subject(:last_played_song) { media_huis_api_processor.last_played_song }

  let(:media_huis_api_processor) { described_class.new(radio_station) }
  let(:radio_station) do
    RadioStation.find_by(name: 'Radio Veronica').presence || create(:radio_veronica)
  end
  let(:response) do
    {
      tracks: [
        {
          createdAt: '2025-04-23T18:05:19.9933333Z',
          stationKey: 'veronica',
          artist: 'Killing Joke',
          title: 'Love Like Blood',
          duration: 262,
          albumArt: '',
          spotifyLink: 'https://open.spotify.com/track/example'
        }
      ]
    }
  end

  describe '#last_played_song' do
    context 'when the response is valid' do
      before do
        allow(media_huis_api_processor).to receive(:make_request).and_return(response)
      end

      it 'returns true' do
        expect(last_played_song).to be true
      end

      it 'sets the correct artist name' do
        last_played_song
        expect(media_huis_api_processor.instance_variable_get(:@artist_name)).to eq('Killing Joke')
      end

      it 'sets the correct title' do
        last_played_song
        expect(media_huis_api_processor.instance_variable_get(:@title)).to eq('Love Like Blood')
      end

      it 'sets the correct broadcasted_at time' do
        last_played_song
        expect(media_huis_api_processor.instance_variable_get(:@broadcasted_at)).to eq(Time.zone.parse('2025-04-23T18:05:19.9933333Z'))
      end

      it 'sets the correct Spotify URL' do
        last_played_song
        expect(media_huis_api_processor.instance_variable_get(:@spotify_url)).to eq('https://open.spotify.com/track/example')
      end
    end

    context 'when the API response is blank' do
      before do
        allow(media_huis_api_processor).to receive(:make_request).and_return(nil)
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

    context 'when the track is blank' do
      before do
        allow(media_huis_api_processor).to receive(:make_request).and_return({ tracks: [] })
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end
  end
end
