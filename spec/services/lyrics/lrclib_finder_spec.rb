# frozen_string_literal: true

require 'rails_helper'

describe Lyrics::LrclibFinder do
  subject(:finder) { described_class.new }

  describe '#find' do
    context 'when LRCLIB returns lyrics for a known track', :use_vcr do
      it 'returns normalized lyrics data', :aggregate_failures do
        result = finder.find(artist_name: 'The Weeknd', track_name: 'Blinding Lights')
        expect(result[:plain_lyrics]).to be_present
        expect(result[:source_url]).to start_with('https://lrclib.net/api/get/')
        expect(result[:id]).to be_present
      end
    end

    context 'when LRCLIB cannot find the track', :use_vcr do
      it 'returns nil' do
        result = finder.find(
          artist_name: 'NonexistentArtistXYZ123',
          track_name: 'NonexistentTrackXYZ123'
        )
        expect(result).to be_nil
      end
    end

    context 'when the request raises' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::ConnectionFailed.new('boom')) # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:sleep) # rubocop:disable RSpec/AnyInstance
        allow(ExceptionNotifier).to receive(:notify)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns nil and notifies' do
        expect(finder.find(artist_name: 'X', track_name: 'Y')).to be_nil
      end
    end
  end

  describe '#fetch_by_id' do
    context 'when the id resolves to a known track', :use_vcr do
      it 'returns normalized lyrics data', :aggregate_failures do
        result = finder.fetch_by_id('390')
        expect(result[:id]).to eq('390')
        expect(result[:plain_lyrics]).to be_present
      end
    end
  end
end
