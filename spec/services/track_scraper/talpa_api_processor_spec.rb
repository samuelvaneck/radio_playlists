# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::TalpaApiProcessor, type: :service do
  describe '#last_played_song' do
    subject(:last_played_song) { talpa_api_processor.last_played_song }

    let(:talpa_api_processor) { described_class.new(radio_station) }
    let(:radio_station) do
      RadioStation.find_by(name: 'Sky Radio') || create(:sky_radio)
    end
    let(:response) do
      {
        data: {
          station: {
            getPlayouts: {
              playouts: [
                {
                  track: {
                    artistName: 'test artist',
                    title: 'test title',
                    isrc: 'TEST12345678'
                  },
                  broadcastDate: '2023-10-01T12:00:00+02:00'
                }
              ]
            }
          }
        }
      }
    end

    before do
      allow(talpa_api_processor).to receive(:make_request).and_return(api_response)
    end

    context 'when the API response is valid' do
      let(:api_response) { response }

      it 'sets the artist name' do
        last_played_song
        expect(talpa_api_processor.instance_variable_get(:@artist_name)).to eq('Test Artist')
      end

      it 'sets the title' do
        last_played_song
        expect(talpa_api_processor.instance_variable_get(:@title)).to eq('Test Title')
      end

      it 'sets the ISRC code' do
        last_played_song
        expect(talpa_api_processor.instance_variable_get(:@isrc_code)).to eq('TEST12345678')
      end

      it 'returns true' do
        expect(last_played_song).to be true
      end
    end

    context 'when the API response is blank' do
      let(:api_response) { nil }

      before do
        allow(Rails.logger).to receive(:warn).and_call_original
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
        expect(Rails.logger).to have_received(:warn).with(/TalpaApiProcessor:/)
      end
    end

    context 'when the API response contains errors' do
      let(:api_response) { { errors: ['Some error occurred'] } }

      before do
        allow(Rails.logger).to receive(:warn).and_call_original
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
        expect(Rails.logger).to have_received(:warn).with(/TalpaApiProcessor:/)
      end
    end
  end
end
