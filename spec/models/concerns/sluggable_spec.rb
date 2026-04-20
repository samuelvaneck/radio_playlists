# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sluggable do
  describe '#set_slug' do
    context 'with Latin characters' do
      let(:artist) { create :artist, name: 'The Weeknd' }

      it 'parameterizes the name' do
        expect(artist.slug).to eq('the-weeknd')
      end
    end

    context 'with Latin diacritics' do
      let(:artist) { create :artist, name: 'Jürgen Müller' }

      it 'transliterates diacritics to ASCII' do
        expect(artist.slug).to eq('jurgen-muller')
      end
    end

    context 'with Cyrillic characters' do
      let(:artist) { create :artist, name: 'Ваня Дмитриенко' }

      it 'transliterates Cyrillic to ASCII' do
        expect(artist.slug).to eq('vanya-dmitrienko')
      end
    end

    context 'with Greek characters' do
      let(:artist) { create :artist, name: 'Ελλάδα' }

      it 'transliterates Greek to ASCII' do
        expect(artist.slug).to eq('ellada')
      end
    end

    context 'when transliteration produces an empty base' do
      let(:artist) { create :artist, name: '!!!' }

      it 'falls back to a model-prefixed random slug' do
        expect(artist.slug).to match(/\Aartist-[0-9a-f]{8}\z/)
      end
    end

    context 'with a duplicate slug source' do
      before { create :artist, name: 'The Weeknd' }

      let(:duplicate) { create :artist, name: 'The Weeknd' }

      it 'appends an incrementing counter' do
        expect(duplicate.slug).to eq('the-weeknd-2')
      end
    end
  end

  describe 'slug updates on name change' do
    let(:artist) { create :artist, name: 'Old Name' }

    before { artist.update(name: 'New Name') }

    it 'regenerates the slug' do
      expect(artist.reload.slug).to eq('new-name')
    end
  end

  describe 'Song slug source' do
    let(:artist) { create :artist, name: 'Ваня Дмитриенко' }
    let(:song) { create :song, title: 'Силуэт', artists: [artist] }

    it 'combines title and first artist name with transliteration' do
      expect(song.slug).to eq('siluet-vanya-dmitrienko')
    end
  end
end
