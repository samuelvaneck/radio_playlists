# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

describe TrackExtractor::ArtistsExtractor do
  subject(:extractor) { described_class.new(played_song:, track:) }

  let(:played_song) do
    OpenStruct.new(
      title: 'Test Song',
      artist_name: 'Test Artist',
      spotify_url: nil,
      isrc_code: nil
    )
  end
  let(:track) { nil }

  describe '#extract' do
    context 'when no track is present' do
      it 'finds or initializes artist by played_song artist_name' do
        result = extractor.extract
        expect(result.name).to eq('Test Artist')
      end

      context 'when artist_name is blank' do
        let(:played_song) do
          OpenStruct.new(
            title: 'Test Song',
            artist_name: '',
            spotify_url: nil,
            isrc_code: nil
          )
        end

        it 'returns nil' do
          expect(extractor.extract).to be_nil
        end
      end
    end

    context 'when track has artists with blank names' do
      let(:track) do
        OpenStruct.new(
          artists: [{ 'name' => 'Valid Artist' }, { 'name' => '' }, { 'name' => nil }],
          spotify_song_url: nil
        )
      end

      it 'filters out artists with blank names' do
        result = extractor.extract
        expect(result.map(&:name)).to eq(['Valid Artist'])
      end
    end

    context 'when track has only blank artist names' do
      let(:track) do
        OpenStruct.new(
          artists: [{ 'name' => '' }, { 'name' => nil }],
          spotify_song_url: nil
        )
      end

      it 'returns an empty array' do
        expect(extractor.extract).to eq([])
      end
    end
  end
end
