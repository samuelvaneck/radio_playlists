# frozen_string_literal: true

describe ChartSongEnrichmentJob do
  describe '#perform' do
    let(:radio_station) { create(:radio_station) }

    context 'when there is a latest song chart' do
      let(:chart) { create(:chart, chart_type: 'songs', date: 1.day.ago) }
      let(:stale_song) { create(:song, title: 'Stale Song', lastfm_enriched_at: 2.days.ago) }
      let(:fresh_song) { create(:song, title: 'Fresh Song', lastfm_enriched_at: 1.hour.ago) }
      let(:never_enriched_song) { create(:song, title: 'Never Enriched', lastfm_enriched_at: nil) }

      before do
        chart.chart_positions.create!(positianable: stale_song, position: 1, counts: 10)
        chart.chart_positions.create!(positianable: fresh_song, position: 2, counts: 8)
        chart.chart_positions.create!(positianable: never_enriched_song, position: 3, counts: 5)

        allow(Spotify::SongEnricher).to receive(:new).and_return(instance_double(Spotify::SongEnricher, enrich: nil))
      end

      it 'enqueues LastfmEnrichmentJob for stale songs' do
        expect(LastfmEnrichmentJob).to receive(:perform_in).with(0.seconds, 'Song', stale_song.id)
        expect(LastfmEnrichmentJob).to receive(:perform_in).with(2.seconds, 'Song', never_enriched_song.id)

        described_class.new.perform
      end

      it 'does not enqueue LastfmEnrichmentJob for fresh songs' do
        allow(LastfmEnrichmentJob).to receive(:perform_in)

        described_class.new.perform

        expect(LastfmEnrichmentJob).not_to have_received(:perform_in).with(anything, 'Song', fresh_song.id)
      end

      it 'calls enrich_with_spotify for stale songs', :aggregate_failures do
        allow(LastfmEnrichmentJob).to receive(:perform_in)

        expect(Spotify::SongEnricher).to receive(:new).with(stale_song, force: true).and_return(
          instance_double(Spotify::SongEnricher, enrich: nil)
        )
        expect(Spotify::SongEnricher).to receive(:new).with(never_enriched_song, force: true).and_return(
          instance_double(Spotify::SongEnricher, enrich: nil)
        )

        described_class.new.perform
      end
    end

    context 'when there is no latest song chart' do
      it 'does not raise an error' do
        expect { described_class.new.perform }.not_to raise_error
      end
    end
  end
end
