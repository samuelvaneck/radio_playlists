# frozen_string_literal: true

require 'rails_helper'

describe Itunes::Base, type: :service do
  let(:args) { { artists: 'Artist Name', title: 'Song Title' } }
  let(:itunes_base) { described_class.new(args) }

  describe '#artist_distance' do
    context 'when artist names match exactly' do
      it 'returns 100' do
        expect(itunes_base.send(:artist_distance, 'Artist Name')).to eq(100)
      end
    end

    context 'when artist names are similar' do
      it 'returns a high score' do
        expect(itunes_base.send(:artist_distance, 'Artist Names')).to be > 80
      end
    end

    context 'when artist names are different' do
      it 'returns a low score' do
        expect(itunes_base.send(:artist_distance, 'Completely Different')).to be < 60
      end
    end

    context 'when multiple artists are in different order with &' do
      let(:args) { { artists: 'Snelle & Zoé Livay', title: 'Song Title' } }

      it 'returns a high score' do
        expect(itunes_base.send(:artist_distance, 'Zoë Livay, Snelle')).to be > 80
      end
    end

    context 'when scraped has feat. separator and API has different order' do
      let(:args) { { artists: 'Artist A feat. Artist B', title: 'Song Title' } }

      it 'returns a high score' do
        expect(itunes_base.send(:artist_distance, 'Artist B & Artist A')).to be > 80
      end
    end
  end

  describe '#title_distance' do
    context 'when titles match exactly' do
      it 'returns 100' do
        expect(itunes_base.send(:title_distance, 'Song Title')).to eq(100)
      end
    end

    context 'when titles are different' do
      it 'returns a low score' do
        expect(itunes_base.send(:title_distance, 'Completely Different')).to be < 60
      end
    end
  end
end
