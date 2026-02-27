# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LastfmEnrichmentJob do
  describe '#perform' do
    let(:job) { described_class.new }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('LASTFM_API_KEY', nil).and_return('test_api_key')
    end

    describe 'enriching an artist' do
      let(:artist) { create(:artist) }

      let(:lastfm_artist_info) do
        {
          'name' => artist.name,
          'stats' => { 'listeners' => '5000000', 'playcount' => '300000000' },
          'tags' => { 'tag' => [{ 'name' => 'Rock' }, { 'name' => 'Alternative' }, { 'name' => 'Britpop' }] }
        }
      end

      before do
        allow_any_instance_of(Lastfm::ArtistFinder).to receive(:get_full_info).and_return(lastfm_artist_info) # rubocop:disable RSpec/AnyInstance
      end

      it 'stores lastfm_listeners on the artist' do
        job.perform('Artist', artist.id)
        expect(artist.reload.lastfm_listeners).to eq(5_000_000)
      end

      it 'stores lastfm_playcount on the artist' do
        job.perform('Artist', artist.id)
        expect(artist.reload.lastfm_playcount).to eq(300_000_000)
      end

      it 'stores lastfm_tags as downcased array' do
        job.perform('Artist', artist.id)
        expect(artist.reload.lastfm_tags).to eq(%w[rock alternative britpop])
      end

      it 'sets lastfm_enriched_at' do
        job.perform('Artist', artist.id)
        expect(artist.reload.lastfm_enriched_at).to be_within(5.seconds).of(Time.current)
      end

      context 'when Last.fm returns a single tag as a hash instead of array' do
        let(:lastfm_artist_info) do
          {
            'name' => artist.name,
            'stats' => { 'listeners' => '1000', 'playcount' => '5000' },
            'tags' => { 'tag' => { 'name' => 'Rock', 'url' => 'https://www.last.fm/tag/rock' } }
          }
        end

        it 'wraps the single tag and stores it as an array' do
          job.perform('Artist', artist.id)
          expect(artist.reload.lastfm_tags).to eq(%w[rock])
        end
      end

      context 'when Last.fm returns no data' do
        before do
          allow_any_instance_of(Lastfm::ArtistFinder).to receive(:get_full_info).and_return(nil) # rubocop:disable RSpec/AnyInstance
        end

        it 'does not update the artist' do
          job.perform('Artist', artist.id)
          expect(artist.reload.lastfm_enriched_at).to be_nil
        end
      end
    end

    describe 'enriching a song' do
      let(:artist) { create(:artist, name: 'Coldplay') }
      let(:song) { create(:song, title: 'Yellow', artists: [artist]) }

      let(:lastfm_track_info) do
        {
          'name' => 'Yellow',
          'listeners' => '3000000',
          'playcount' => '50000000',
          'toptags' => { 'tag' => [{ 'name' => 'Rock' }, { 'name' => 'Alternative' }] }
        }
      end

      before do
        allow_any_instance_of(Lastfm::TrackFinder).to receive(:get_info).and_return(lastfm_track_info) # rubocop:disable RSpec/AnyInstance
      end

      it 'stores lastfm_listeners on the song' do
        job.perform('Song', song.id)
        expect(song.reload.lastfm_listeners).to eq(3_000_000)
      end

      it 'stores lastfm_playcount on the song' do
        job.perform('Song', song.id)
        expect(song.reload.lastfm_playcount).to eq(50_000_000)
      end

      it 'stores lastfm_tags as downcased array' do
        job.perform('Song', song.id)
        expect(song.reload.lastfm_tags).to eq(%w[rock alternative])
      end

      it 'sets lastfm_enriched_at' do
        job.perform('Song', song.id)
        expect(song.reload.lastfm_enriched_at).to be_within(5.seconds).of(Time.current)
      end

      context 'when song has no artists' do
        let(:song) { create(:song, title: 'Yellow') }

        before { song.artists.destroy_all }

        it 'does not update the song' do
          job.perform('Song', song.id)
          expect(song.reload.lastfm_enriched_at).to be_nil
        end
      end

      context 'when Last.fm returns no data' do
        before do
          allow_any_instance_of(Lastfm::TrackFinder).to receive(:get_info).and_return(nil) # rubocop:disable RSpec/AnyInstance
        end

        it 'does not update the song' do
          job.perform('Song', song.id)
          expect(song.reload.lastfm_enriched_at).to be_nil
        end
      end
    end
  end

  describe '.enqueue_all' do
    let!(:artist_not_enriched) { create(:artist, lastfm_enriched_at: nil) }
    let!(:artist_stale) { create(:artist, lastfm_enriched_at: 31.days.ago) }
    let!(:artist_fresh) { create(:artist, lastfm_enriched_at: 1.day.ago) }
    let!(:song_not_enriched) { create(:song, lastfm_enriched_at: nil) }
    let!(:song_fresh) { create(:song, lastfm_enriched_at: 1.day.ago) }

    before do
      allow(described_class).to receive(:perform_in)
    end

    it 'enqueues artists that need enrichment', :aggregate_failures do
      described_class.enqueue_all
      expect(described_class).to have_received(:perform_in).with(anything, 'Artist', artist_not_enriched.id)
      expect(described_class).to have_received(:perform_in).with(anything, 'Artist', artist_stale.id)
    end

    it 'does not enqueue fresh artists' do
      described_class.enqueue_all
      expect(described_class).not_to have_received(:perform_in).with(anything, 'Artist', artist_fresh.id)
    end

    it 'enqueues songs that need enrichment' do
      described_class.enqueue_all
      expect(described_class).to have_received(:perform_in).with(anything, 'Song', song_not_enriched.id)
    end

    it 'does not enqueue fresh songs' do
      described_class.enqueue_all
      expect(described_class).not_to have_received(:perform_in).with(anything, 'Song', song_fresh.id)
    end
  end
end
