# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lyrics::ThemeTranslator do
  describe '.translate' do
    it 'returns the Dutch label for a known English theme' do
      expect(described_class.translate('love')).to eq('liefde')
    end

    it 'is case-insensitive and trims whitespace' do
      expect(described_class.translate('  Heartbreak ')).to eq('liefdesverdriet')
    end

    it 'returns the original tag for an unmapped theme' do
      expect(described_class.translate('zeitgeist')).to eq('zeitgeist')
    end

    it 'returns nil for nil input' do
      expect(described_class.translate(nil)).to be_nil
    end

    it 'maps multi-word themes' do
      expect(described_class.translate('mental health')).to eq('mentale gezondheid')
    end

    it 'treats hyphenated and unhyphenated variants the same' do
      expect([described_class.translate('self-acceptance'), described_class.translate('self acceptance')])
        .to all(eq('zelfacceptatie'))
    end
  end

  describe '.translate_all' do
    it 'translates each theme in the array' do
      expect(described_class.translate_all(%w[love hope drugs])).to eq(%w[liefde hoop drugs])
    end

    it 'returns an empty array for nil input' do
      expect(described_class.translate_all(nil)).to eq([])
    end
  end

  describe '.mapped?' do
    it 'is true for a known theme' do
      expect(described_class.mapped?('love')).to be(true)
    end

    it 'is false for an unmapped theme' do
      expect(described_class.mapped?('quantum entanglement')).to be(false)
    end
  end
end
