# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MusicBrainz::RecordingFinder, type: :service do
  let(:song) { create(:song, title: 'Test Song', isrc: 'USRC12345678') }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:finder) { described_class.new(song) }

  before do
    song.artists << artist
  end

  let(:successful_response) do
    {
      'recordings' => [
        {
          'id' => 'mb-recording-123',
          'title' => 'Test Song',
          'artist-credit' => [
            { 'name' => 'Test Artist' }
          ]
        }
      ]
    }
  end

  let(:empty_response) do
    { 'recordings' => [] }
  end

  describe '#find_recording_id' do
    context 'when song has ISRC and is found' do
      before do
        stub_request(:get, /musicbrainz.org.*isrc/)
          .to_return(status: 200, body: successful_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the recording ID' do
        expect(finder.find_recording_id).to eq('mb-recording-123')
      end

      it 'sets the title' do
        finder.find_recording_id
        expect(finder.title).to eq('Test Song')
      end

      it 'sets the artist_name' do
        finder.find_recording_id
        expect(finder.artist_name).to eq('Test Artist')
      end
    end

    context 'when ISRC search returns no results but title/artist search succeeds' do
      let(:song) { create(:song, title: 'Another Song', isrc: 'NORC00000000') }

      before do
        stub_request(:get, /musicbrainz.org.*isrc/)
          .to_return(status: 200, body: empty_response.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, /musicbrainz.org.*recording/)
          .to_return(status: 200, body: successful_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the recording ID from title/artist search' do
        expect(finder.find_recording_id).to eq('mb-recording-123')
      end
    end

    context 'when song has no ISRC' do
      let(:song) { create(:song, title: 'No ISRC Song', isrc: nil) }

      before do
        stub_request(:get, /musicbrainz.org/)
          .to_return(status: 200, body: successful_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'searches by title and artist' do
        finder.find_recording_id
        expect(WebMock).to have_requested(:get, /musicbrainz.org/).with(query: hash_including('query' => /recording/))
      end
    end

    context 'when no results are found' do
      before do
        stub_request(:get, /musicbrainz.org/)
          .to_return(status: 200, body: empty_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns nil' do
        expect(finder.find_recording_id).to be_nil
      end
    end

    context 'when API returns an error' do
      before do
        stub_request(:get, /musicbrainz.org/)
          .to_return(status: 503, body: 'Service Unavailable')
      end

      it 'returns nil' do
        expect(finder.find_recording_id).to be_nil
      end
    end

    context 'when API returns invalid JSON' do
      before do
        stub_request(:get, /musicbrainz.org/)
          .to_return(status: 200, body: 'not json')
      end

      it 'returns nil' do
        expect(finder.find_recording_id).to be_nil
      end
    end

    context 'when recording has multiple artists' do
      let(:multi_artist_response) do
        {
          'recordings' => [
            {
              'id' => 'mb-recording-456',
              'title' => 'Collaboration',
              'artist-credit' => [
                { 'name' => 'Artist One' },
                { 'name' => 'Artist Two' }
              ]
            }
          ]
        }
      end

      before do
        stub_request(:get, /musicbrainz.org/)
          .to_return(status: 200, body: multi_artist_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'joins artist names with comma' do
        finder.find_recording_id
        expect(finder.artist_name).to eq('Artist One, Artist Two')
      end
    end
  end
end
