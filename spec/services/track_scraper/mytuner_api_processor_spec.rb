# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::MytunerApiProcessor, type: :service do
  subject(:last_played_song) { processor.last_played_song }

  let(:processor) { described_class.new(radio_station) }
  let(:radio_station) do
    RadioStation.find_by(name: 'Decibel').presence || create(:decibel)
  end
  let(:register_response) do
    { 'success' => true, 'access_token' => 'test_token_123' }
  end
  let(:playlist_response) do
    {
      'success' => true,
      'data' => [
        [
          {
            'start_time' => 1_774_828_916,
            'title' => 'Reality (feat. Janieck)',
            'artist' => 'Lost Frequencies',
            'artwork_url' => 'https://example.com/artwork.jpg'
          },
          {
            'start_time' => 1_774_829_092,
            'title' => 'No Diggity',
            'artist' => 'Blackstreet',
            'artwork_url' => 'https://example.com/artwork2.jpg'
          }
        ]
      ],
      'count' => 2,
      'distinct' => 2
    }
  end

  describe '#last_played_song' do
    before do
      allow(processor).to receive_messages(register_widget: register_response['access_token'],
                                           fetch_playlist: playlist_response)
    end

    context 'when the API response is valid' do
      it 'returns true' do
        expect(last_played_song).to be true
      end

      it 'sets the artist name' do
        last_played_song
        expect(processor.artist_name).to eq('Blackstreet')
      end

      it 'sets the title' do
        last_played_song
        expect(processor.title).to eq('No Diggity')
      end

      it 'sets the broadcasted_at from the most recent track' do
        last_played_song
        expect(processor.broadcasted_at).to eq(Time.zone.at(1_774_829_092))
      end

      it 'sets the raw response' do
        last_played_song
        expect(processor.raw_response).to be_present
      end
    end

    context 'when the registration fails' do
      before do
        allow(processor).to receive(:register_widget).and_return(nil)
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when the playlist response is blank' do
      before do
        allow(processor).to receive(:fetch_playlist).and_return(nil)
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when the playlist has no tracks' do
      before do
        allow(processor).to receive(:fetch_playlist).and_return({ 'success' => true, 'data' => [[]] })
      end

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end
  end
end
