# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::BorderlineMatchValidator, type: :service do
  let(:validator) do
    described_class.new(
      scraped_title: scraped_title,
      scraped_artist: scraped_artist,
      matched_title: matched_title,
      matched_artist: matched_artist
    )
  end

  let(:scraped_artist) { 'The Weeknd' }
  let(:scraped_title) { 'Blinding Lights' }
  let(:matched_artist) { 'The Weeknd' }
  let(:matched_title) { 'Blinding Lights (Radio Edit)' }

  describe '#same_song?' do
    subject(:same_song) { validator.same_song? }

    context 'when the LLM confirms the songs match' do
      before do
        allow(validator).to receive(:chat).and_return('yes')
      end

      it 'returns true' do
        expect(same_song).to be true
      end
    end

    context 'when the LLM confirms with additional text' do
      before do
        allow(validator).to receive(:chat).and_return('Yes, these are the same song.')
      end

      it 'returns true' do
        expect(same_song).to be true
      end
    end

    context 'when the LLM says the songs do not match' do
      before do
        allow(validator).to receive(:chat).and_return('no')
      end

      it 'returns false' do
        expect(same_song).to be false
      end
    end

    context 'when the LLM returns nil' do
      before do
        allow(validator).to receive(:chat).and_return(nil)
      end

      it 'returns false' do
        expect(same_song).to be false
      end
    end

    context 'when the LLM returns an empty string' do
      before do
        allow(validator).to receive(:chat).and_return('')
      end

      it 'returns false' do
        expect(same_song).to be false
      end
    end

    context 'when the LLM returns unexpected text' do
      before do
        allow(validator).to receive(:chat).and_return('I am not sure about this match')
      end

      it 'returns false' do
        expect(same_song).to be false
      end
    end
  end

  describe 'BORDERLINE_TITLE_RANGE' do
    it 'covers 60 through 69', :aggregate_failures do
      expect(described_class::BORDERLINE_TITLE_RANGE).to cover(60)
      expect(described_class::BORDERLINE_TITLE_RANGE).to cover(69)
      expect(described_class::BORDERLINE_TITLE_RANGE).not_to cover(70)
      expect(described_class::BORDERLINE_TITLE_RANGE).not_to cover(59)
    end
  end
end
