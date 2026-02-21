# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MusicBrainz::IsrcsFinder, type: :service do
  let(:isrc) { 'USRC12345678' }
  let(:finder) { described_class.new(isrc) }
  let(:recording_id) { 'mb-recording-123' }

  let(:isrc_lookup_response) do
    {
      'recordings' => [
        { 'id' => recording_id, 'title' => 'Test Song' }
      ]
    }
  end

  let(:recording_response) do
    {
      'id' => recording_id,
      'isrcs' => %w[USRC12345678 GBABC1234567 NLA5E2300100]
    }
  end

  describe '#find' do
    context 'when ISRC is blank' do
      let(:isrc) { nil }

      it 'returns an empty array' do
        expect(finder.find).to eq([])
      end
    end

    context 'when recording is found with multiple ISRCs' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/isrc/#{isrc}})
          .to_return(status: 200, body: isrc_lookup_response.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, %r{musicbrainz.org/ws/2/recording/#{recording_id}})
          .to_return(status: 200, body: recording_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns all ISRCs for the recording' do
        expect(finder.find).to eq(%w[USRC12345678 GBABC1234567 NLA5E2300100])
      end
    end

    context 'when no recordings are found for the ISRC' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/isrc/#{isrc}})
          .to_return(status: 200, body: { 'recordings' => [] }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an empty array' do
        expect(finder.find).to eq([])
      end
    end

    context 'when the ISRC lookup API returns an error' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/isrc/#{isrc}})
          .to_return(status: 503, body: 'Service Unavailable')
      end

      it 'returns an empty array' do
        expect(finder.find).to eq([])
      end
    end

    context 'when the recording API returns an error' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/isrc/#{isrc}})
          .to_return(status: 200, body: isrc_lookup_response.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, %r{musicbrainz.org/ws/2/recording/#{recording_id}})
          .to_return(status: 503, body: 'Service Unavailable')
      end

      it 'returns an empty array' do
        expect(finder.find).to eq([])
      end
    end

    context 'when the ISRC lookup returns invalid JSON' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/isrc/#{isrc}})
          .to_return(status: 200, body: 'not json', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an empty array' do
        expect(finder.find).to eq([])
      end
    end

    context 'when the recording response returns invalid JSON' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/isrc/#{isrc}})
          .to_return(status: 200, body: isrc_lookup_response.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, %r{musicbrainz.org/ws/2/recording/#{recording_id}})
          .to_return(status: 200, body: 'not json', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an empty array' do
        expect(finder.find).to eq([])
      end
    end

    context 'when recording has no ISRCs' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/isrc/#{isrc}})
          .to_return(status: 200, body: isrc_lookup_response.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, %r{musicbrainz.org/ws/2/recording/#{recording_id}})
          .to_return(status: 200, body: { 'id' => recording_id, 'isrcs' => [] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an empty array' do
        expect(finder.find).to eq([])
      end
    end
  end
end
