# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LyricsEnrichmentJob do
  let(:job) { described_class.new }
  let(:artist) { create(:artist, name: 'The Weeknd') }
  let(:song) { create(:song, title: 'Blinding Lights', duration_ms: 200_000, artists: [artist]) }
  let(:lrclib_payload) do
    {
      id: '390',
      plain_lyrics: "Yeah\nI've been tryna call",
      track_name: 'Blinding Lights',
      artist_name: 'The Weeknd',
      album_name: 'After Hours',
      duration: 200.0,
      source_url: 'https://lrclib.net/api/get/390'
    }
  end
  let(:sentiment_payload) do
    { sentiment: -0.2, themes: %w[loneliness love], language: 'en', confidence: 0.8 }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LYRICS_ENRICHMENT_ENABLED').and_return('true')
  end

  describe '#perform' do
    before do
      allow_any_instance_of(Lyrics::LrclibFinder).to receive(:find).and_return(lrclib_payload) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Llm::LyricsSentimentAnalyzer).to receive(:analyze).and_return(sentiment_payload) # rubocop:disable RSpec/AnyInstance
    end

    it 'creates a Lyric record with sentiment data' do
      expect { job.perform(song.id) }.to change(Lyric, :count).by(1)
    end

    context 'with a song that has no existing lyric' do
      let(:lyric) do
        job.perform(song.id)
        song.reload.lyric
      end
      let(:expected_attributes) do
        { sentiment: -0.2, themes: %w[loneliness love], language: 'en',
          source: 'lrclib', source_id: '390', source_url: 'https://lrclib.net/api/get/390' }
      end

      it 'persists the analyzer output and source metadata', :aggregate_failures do
        expect(lyric).to have_attributes(expected_attributes)
        expect(lyric.enriched_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context 'when LYRICS_ENRICHMENT_ENABLED is not set' do
      before { allow(ENV).to receive(:[]).with('LYRICS_ENRICHMENT_ENABLED').and_return(nil) }

      it 'does not create a lyric' do
        expect { job.perform(song.id) }.not_to change(Lyric, :count)
      end
    end

    context 'when LRCLIB returns nothing' do
      before do
        allow_any_instance_of(Lyrics::LrclibFinder).to receive(:find).and_return(nil) # rubocop:disable RSpec/AnyInstance
      end

      it 'does not create a lyric' do
        expect { job.perform(song.id) }.not_to change(Lyric, :count)
      end
    end

    context 'when sentiment analyzer returns nil' do
      before do
        allow_any_instance_of(Llm::LyricsSentimentAnalyzer).to receive(:analyze).and_return(nil) # rubocop:disable RSpec/AnyInstance
      end

      it 'does not create a lyric' do
        expect { job.perform(song.id) }.not_to change(Lyric, :count)
      end
    end

    context 'when the song already has a lyric' do
      let!(:existing) { create(:lyric, song: song, sentiment: 0.5, enriched_at: 1.year.ago) }

      it 'updates the existing record in place', :aggregate_failures do
        expect { job.perform(song.id) }.not_to change(Lyric, :count)
        expect(existing.reload.sentiment).to eq(-0.2)
      end
    end

    context 'when the song has no artist' do
      let(:song) { create(:song, title: 'X', duration_ms: nil) }

      before { song.artists.destroy_all }

      it 'does not create a lyric' do
        expect { job.perform(song.id) }.not_to change(Lyric, :count)
      end
    end
  end

  describe '.enqueue_all' do
    let!(:radio_station) { create(:radio_station) }
    let!(:song_played_recently) { create(:song, artists: [artist]) }
    let!(:song_played_long_ago) { create(:song) }
    let(:song_with_fresh_lyric) { create(:song, artists: [artist]) }

    before do
      create(:air_play, song: song_played_recently, radio_station: radio_station, broadcasted_at: 1.day.ago)
      create(:air_play, song: song_played_long_ago, radio_station: radio_station, broadcasted_at: 30.days.ago)
      create(:air_play, song: song_with_fresh_lyric, radio_station: radio_station, broadcasted_at: 1.day.ago)
      create(:lyric, song: song_with_fresh_lyric, enriched_at: 1.day.ago)
      allow(described_class).to receive(:perform_in)
    end

    it 'enqueues recently-played songs missing fresh lyrics' do
      described_class.enqueue_all
      expect(described_class).to have_received(:perform_in).with(anything, song_played_recently.id)
    end

    it 'skips songs not played in the last week' do
      described_class.enqueue_all
      expect(described_class).not_to have_received(:perform_in).with(anything, song_played_long_ago.id)
    end

    it 'skips songs with fresh lyrics' do
      described_class.enqueue_all
      expect(described_class).not_to have_received(:perform_in).with(anything, song_with_fresh_lyric.id)
    end

    context 'when LYRICS_ENRICHMENT_ENABLED is not set' do
      before { allow(ENV).to receive(:[]).with('LYRICS_ENRICHMENT_ENABLED').and_return(nil) }

      it 'does not enqueue anything' do
        described_class.enqueue_all
        expect(described_class).not_to have_received(:perform_in)
      end
    end
  end
end
