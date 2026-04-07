# frozen_string_literal: true

require 'rails_helper'

describe IsrcCrossContaminationRepair do
  let(:snelle) { create(:artist, name: 'Snelle') }
  let(:zoe) { create(:artist, name: 'Zoë Livay') }

  describe '#run' do
    context 'when a song has ISRCs from a different recording' do
      let!(:ik_zing) do
        create(:song,
               title: 'Ik Zing (feat. Snelle)',
               id_on_spotify: 'ik_zing_spotify',
               isrcs: %w[NLA802500027 NLS242600073],
               artists: [zoe, snelle])
      end

      let!(:laat_het_licht) do
        create(:song,
               title: 'Laat Het Licht Aan',
               id_on_spotify: 'laat_spotify',
               isrcs: ['NLS242600073'],
               artists: [snelle])
      end

      context 'with dry_run: true' do
        let(:repair) { described_class.new(dry_run: true) }

        it 'detects contamination but does not fix it', :aggregate_failures do
          results = repair.run
          expect(results[:checked]).to be >= 1
          expect(results[:contaminated]).to eq(1)
          expect(results[:fixed]).to eq(0)
          ik_zing.reload
          expect(ik_zing.isrcs).to eq(%w[NLA802500027 NLS242600073])
        end
      end

      context 'with dry_run: false' do
        let(:repair) { described_class.new(dry_run: false) }

        it 'removes the foreign ISRC from the contaminated song', :aggregate_failures do
          results = repair.run
          expect(results[:contaminated]).to eq(1)
          expect(results[:fixed]).to eq(1)
          ik_zing.reload
          expect(ik_zing.isrcs).to eq(['NLA802500027'])
        end

        it 'does not modify the other song' do
          repair.run
          laat_het_licht.reload
          expect(laat_het_licht.isrcs).to eq(['NLS242600073'])
        end
      end
    end

    context 'when a song has multiple ISRCs from the same recording' do
      let(:repair) { described_class.new(dry_run: true) }

      before do
        create(:song,
               title: 'Zwart Wit',
               id_on_spotify: 'zwart_wit_spotify',
               isrcs: %w[NLA200200321 NLA200200322],
               artists: [create(:artist, name: 'Frank Boeijen Groep')])
      end

      it 'does not flag songs with ISRCs not found on other songs' do
        results = repair.run
        expect(results[:contaminated]).to eq(0)
      end
    end

    context 'when no songs have multiple ISRCs' do
      let(:repair) { described_class.new(dry_run: true) }

      before do
        create(:song,
               title: 'Clean Song',
               id_on_spotify: 'clean_spotify',
               isrcs: ['ISRC001'],
               artists: [snelle])
      end

      it 'reports nothing', :aggregate_failures do
        results = repair.run
        expect(results[:checked]).to eq(0)
        expect(results[:contaminated]).to eq(0)
      end
    end
  end
end
