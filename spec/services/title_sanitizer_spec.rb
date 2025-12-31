# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TitleSanitizer do
  describe '.sanitize' do
    context 'when title has chart position prefix with hash and colon' do
      it 'removes "#89: " prefix' do
        expect(described_class.sanitize('#89: Enjoy The Silence')).to eq('Enjoy The Silence')
      end

      it 'removes "#1: " prefix' do
        expect(described_class.sanitize('#1: Bohemian Rhapsody')).to eq('Bohemian Rhapsody')
      end

      it 'removes "#100: " prefix' do
        expect(described_class.sanitize('#100: Sweet Child O Mine')).to eq('Sweet Child O Mine')
      end

      it 'removes "#10000: " prefix' do
        expect(described_class.sanitize('#10000: Some Deep Cut')).to eq('Some Deep Cut')
      end
    end

    context 'when title has chart position prefix with hash and period' do
      it 'removes "#89. " prefix' do
        expect(described_class.sanitize('#89. Enjoy The Silence')).to eq('Enjoy The Silence')
      end
    end

    context 'when title has chart position prefix without hash' do
      it 'removes "89: " prefix' do
        expect(described_class.sanitize('89: Enjoy The Silence')).to eq('Enjoy The Silence')
      end

      it 'removes "1. " prefix' do
        expect(described_class.sanitize('1. Bohemian Rhapsody')).to eq('Bohemian Rhapsody')
      end
    end

    context 'when title has no chart position prefix' do
      it 'returns the title unchanged' do
        expect(described_class.sanitize('Enjoy The Silence')).to eq('Enjoy The Silence')
      end

      it 'handles titles with numbers in the middle' do
        expect(described_class.sanitize('Summer of 69')).to eq('Summer of 69')
      end

      it 'handles titles starting with hash but not a chart position' do
        expect(described_class.sanitize('#Selfie')).to eq('#Selfie')
      end
    end

    context 'when title has extra whitespace' do
      it 'strips leading and trailing whitespace' do
        expect(described_class.sanitize('  Enjoy The Silence  ')).to eq('Enjoy The Silence')
      end

      it 'strips whitespace after removing chart position' do
        expect(described_class.sanitize('#89:   Enjoy The Silence')).to eq('Enjoy The Silence')
      end
    end

    context 'when title is nil or empty' do
      it 'handles nil input' do
        expect(described_class.sanitize(nil)).to eq('')
      end

      it 'handles empty string' do
        expect(described_class.sanitize('')).to eq('')
      end
    end
  end

  describe '#sanitize' do
    it 'works as instance method' do
      sanitizer = described_class.new('#89: Enjoy The Silence')
      expect(sanitizer.sanitize).to eq('Enjoy The Silence')
    end
  end
end
