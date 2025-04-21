# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::SlamApiProcessor, type: :service do
  describe '#last_played_song' do
    subject(:last_played_song) { slam_api_processor.last_played_song }

    let(:slam_api_processor) { described_class.new(radio_station) }
    let(:radio_station) do
      RadioStation.find_by(name: 'SLAM!') || create(:slam)
    end
    let(:response) do
      {
        data: {
          song: {
            artist: 'test artist',
            title: 'test title'
          }
        }
      }
    end

    before do
      allow(slam_api_processor).to receive(:make_request).and_return(api_response)
    end

    context 'when the API response is valid' do
      let(:api_response) { response }

      it 'sets the artist name' do
        last_played_song
        expect(slam_api_processor.instance_variable_get(:@artist_name)).to eq('Test Artist')
      end

      it 'sets the title' do
        last_played_song
        expect(slam_api_processor.instance_variable_get(:@title)).to eq('Test Title')
      end

      it 'sets the broadcasted_at timestamp' do
        last_played_song
        expect(slam_api_processor.instance_variable_get(:@broadcasted_at)).to be_within(1.second).of(Time.zone.now)
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
