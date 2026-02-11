# spec/services/radio_listener_spec.rb
require 'rails_helper'

describe RadioListener, type: :service do
  let(:radio_station) { RadioStation.find_by(name: 'Sky Radio') || create(:sky_radio) }
  let(:radio_listener) { described_class.new(radio_station:) }

  describe '#listen' do
    context 'when the response is successful' do
      let(:response_body) do
        {
          'result' => {
            'song' => {
              'artist' => 'Ed Sheeran',
              'title' => 'Shape of You',
              'spotify_url' => 'https://spotify.com/track/123',
              'isrc' => 'USAT21700123'
            }
          }
        }
      end

      before do
        stub_request(:post, "#{ENV['RADIO_LISTENER_URL']}/listen")
          .with(body: { url: radio_station.direct_stream_url }.to_json)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns true' do
        expect(radio_listener.listen).to be true
      end

      it 'returns the artist name' do
        radio_listener.listen
        expect(radio_listener.artist_name).to eq('Ed Sheeran')
      end

      it 'returns the title' do
        radio_listener.listen
        expect(radio_listener.title).to eq('Shape of You')
      end

      it 'returns the Spotify URL' do
        radio_listener.listen
        expect(radio_listener.spotify_url).to eq('https://spotify.com/track/123')
      end

      it 'returns the ISRC code' do
        radio_listener.listen
        expect(radio_listener.isrc_code).to eq('USAT21700123')
      end
    end

    context 'when the response is unsuccessful' do
      before do
        stub_request(:post, "#{ENV['RADIO_LISTENER_URL']}/listen")
          .with(body: { url: radio_station.direct_stream_url }.to_json)
          .to_return(status: 500, body: { error: 'Internal Server Error' }.to_json)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns false' do
        expect(radio_listener.listen).to be false
      end

      it 'logs the error' do
        radio_listener.listen
        expect(Rails.logger).to have_received(:error).with(/RadioListener error: 500/)
      end
    end

    context 'when the response does not contain a song' do
      let(:response_body) { { 'result' => { 'song' => nil } } }

      before do
        stub_request(:post, "#{ENV['RADIO_LISTENER_URL']}/listen")
          .with(body: { url: radio_station.direct_stream_url }.to_json)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns false' do
        expect(radio_listener.listen).to be false
      end
    end
  end
end
