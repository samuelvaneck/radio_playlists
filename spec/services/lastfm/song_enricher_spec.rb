# frozen_string_literal: true

require 'rails_helper'

describe Lastfm::SongEnricher, :use_vcr do
  subject(:song_enricher) { described_class.new }

  let(:artist) { create(:artist, name: 'The Beatles') }
  let(:song) { create(:song, title: 'Hey Jude', artists: [artist]) }

  describe '#enrich_song' do
    subject(:enrich_result) { song_enricher.enrich_song(song) }

    context 'with valid song and successful API responses' do
      it 'returns the enriched song' do
        expect(enrich_result).to eq(song)
      end

      it 'updates song lastfm_url' do
        enrich_result
        song.reload
        expect(song.lastfm_url).to be_present
      end

      it 'updates song lastfm_listeners' do
        enrich_result
        song.reload
        expect(song.lastfm_listeners).to be_present
      end

      it 'updates song lastfm_playcount' do
        enrich_result
        song.reload
        expect(song.lastfm_playcount).to be_present
      end

      it 'updates song lastfm_mbid' do
        enrich_result
        song.reload
        expect(song.lastfm_mbid).to be_present
      end

      it 'enriches artist lastfm_url' do
        enrich_result
        artist.reload
        expect(artist.lastfm_url).to be_present
      end

      it 'enriches artist lastfm_listeners' do
        enrich_result
        artist.reload
        expect(artist.lastfm_listeners).to be_present
      end

      it 'enriches artist lastfm_playcount' do
        enrich_result
        artist.reload
        expect(artist.lastfm_playcount).to be_present
      end

      it 'enriches artist lastfm_tags' do
        enrich_result
        artist.reload
        expect(artist.lastfm_tags).to be_present
      end

      it 'enriches artist lastfm_mbid' do
        enrich_result
        artist.reload
        expect(artist.lastfm_mbid).to be_present
      end

      it 'enriches artist lastfm_bio' do
        enrich_result
        artist.reload
        expect(artist.lastfm_bio).to be_present
      end
    end

    context 'with invalid inputs' do
      context 'when song is not a Song instance' do
        subject(:enrich_result) { song_enricher.enrich_song('not_a_song') }

        it 'returns nil' do
          expect(enrich_result).to be_nil
        end
      end

      context 'when song has no artists' do
        subject(:enrich_result) { song_enricher.enrich_song(song_without_artists) }

        let(:song_without_artists) { create(:song, title: 'Test Song', artists: []) }

        it 'returns nil' do
          expect(enrich_result).to be_nil
        end
      end
    end

    context 'when track is not found' do
      subject(:enrich_result) { song_enricher.enrich_song(unknown_song) }

      let(:unknown_song) do
        create(:song, title: 'Unknown Song XYZ',
                      artists: [create(:artist, name: 'Unknown Artist XYZ')])
      end

      it 'returns nil' do
        expect(enrich_result).to be_nil
      end

      it 'does not update song' do
        expect { enrich_result }.not_to(change { unknown_song.reload.attributes })
      end
    end

    context 'when an error occurs' do
      before do
        allow(song_enricher.instance_variable_get(:@track_finder)).to receive(:get_info).and_raise(StandardError, 'API Error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        enrich_result
        expect(Rails.logger).to have_received(:error).with(/Last.fm song enrichment error for song #{song.id}: API Error/)
      end

      it 'returns nil' do
        expect(enrich_result).to be_nil
      end
    end
  end

  describe '#enrich_artist' do
    subject(:enrich_result) { song_enricher.enrich_artist(artist) }

    context 'with valid artist and successful API response' do
      it 'returns the enriched artist' do
        expect(enrich_result).to eq(artist)
      end

      it 'updates artist lastfm_url' do
        enrich_result
        artist.reload
        expect(artist.lastfm_url).to be_present
      end

      it 'updates artist lastfm_listeners' do
        enrich_result
        artist.reload
        expect(artist.lastfm_listeners).to be_present
      end

      it 'updates artist lastfm_playcount' do
        enrich_result
        artist.reload
        expect(artist.lastfm_playcount).to be_present
      end

      it 'updates artist lastfm_tags' do
        enrich_result
        artist.reload
        expect(artist.lastfm_tags).to be_present
      end

      it 'updates artist lastfm_mbid' do
        enrich_result
        artist.reload
        expect(artist.lastfm_mbid).to be_present
      end

      it 'updates artist lastfm_bio' do
        enrich_result
        artist.reload
        expect(artist.lastfm_bio).to be_present
      end
    end

    context 'with invalid inputs' do
      context 'when artist is not an Artist instance' do
        subject(:enrich_result) { song_enricher.enrich_artist('not_an_artist') }

        it 'returns nil' do
          expect(enrich_result).to be_nil
        end
      end
    end

    context 'when artist is not found' do
      subject(:enrich_result) { song_enricher.enrich_artist(unknown_artist) }

      let(:unknown_artist) { create(:artist, name: 'Unknown Artist XYZ') }

      it 'returns nil' do
        expect(enrich_result).to be_nil
      end

      it 'does not update artist' do
        expect { enrich_result }.not_to(change { unknown_artist.reload.attributes })
      end
    end

    context 'when an error occurs' do
      before do
        allow(song_enricher.instance_variable_get(:@artist_finder)).to receive(:get_info).and_raise(StandardError, 'API Error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        enrich_result
        expect(Rails.logger).to have_received(:error).with(/Last.fm artist enrichment error for artist #{artist.id}: API Error/)
      end

      it 'returns nil' do
        expect(enrich_result).to be_nil
      end
    end
  end

  describe '#search_tracks' do
    subject(:search_result) { song_enricher.search_tracks(query, limit: limit) }

    let(:limit) { 3 }

    context 'with artist - track format' do
      let(:query) { 'The Beatles - Hey Jude' }

      it 'returns an Array' do
        expect(search_result).to be_an(Array)
      end

      it 'returns non-empty results' do
        expect(search_result).not_to be_empty
      end

      it 'includes name field in first result' do
        first_result = search_result.first
        expect(first_result).to include(:name) if first_result
      end

      it 'includes artist field in first result' do
        first_result = search_result.first
        expect(first_result).to include(:artist) if first_result
      end

      it 'includes url field in first result' do
        first_result = search_result.first
        expect(first_result).to include(:url) if first_result
      end
    end

    context 'with generic query format' do
      let(:query) { 'Hey Jude' }

      it 'returns an Array' do
        expect(search_result).to be_an(Array)
      end
    end

    context 'with blank query' do
      let(:query) { '' }

      it 'returns empty array' do
        expect(search_result).to eq([])
      end
    end

    context 'with unknown query' do
      let(:query) { 'Unknown Song XYZ - Unknown Artist XYZ' }

      it 'returns an Array' do
        expect(search_result).to be_an(Array)
      end
    end

    context 'when an error occurs' do
      let(:query) { 'The Beatles - Hey Jude' }

      before do
        allow(song_enricher.instance_variable_get(:@track_finder)).to receive(:search).and_raise(StandardError, 'Search Error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        search_result
        expect(Rails.logger).to have_received(:error).with(/Last.fm track search error: Search Error/)
      end

      it 'returns empty array' do
        expect(search_result).to eq([])
      end
    end
  end

  describe '#search_artists' do
    subject(:search_result) { song_enricher.search_artists(query, limit: limit) }

    let(:query) { 'The Beatles' }
    let(:limit) { 3 }

    context 'with valid query' do
      it 'returns an Array' do
        expect(search_result).to be_an(Array)
      end

      it 'returns non-empty results' do
        expect(search_result).not_to be_empty
      end

      it 'includes name field in first result' do
        first_result = search_result.first
        expect(first_result).to include(:name) if first_result
      end
    end

    context 'with blank query' do
      let(:query) { '' }

      it 'returns empty array' do
        expect(search_result).to eq([])
      end
    end

    context 'with unknown query' do
      let(:query) { 'Unknown Artist XYZ' }

      it 'returns an Array' do
        expect(search_result).to be_an(Array)
      end
    end

    context 'when an error occurs' do
      before do
        allow(song_enricher.instance_variable_get(:@artist_finder)).to receive(:search).and_raise(StandardError, 'Search Error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        search_result
        expect(Rails.logger).to have_received(:error).with(/Last.fm artist search error: Search Error/)
      end

      it 'returns empty array' do
        expect(search_result).to eq([])
      end
    end
  end

  describe '#get_similar_tracks' do
    subject(:similar_result) { song_enricher.get_similar_tracks(song, limit: limit) }

    let(:limit) { 3 }

    context 'with valid song' do
      it 'returns an Array' do
        expect(similar_result).to be_an(Array)
      end

      context 'when similar tracks exist' do
        it 'includes name field in first result' do
          first_similar = similar_result.first
          expect(first_similar).to include(:name) if first_similar
        end

        it 'includes artist field in first result' do
          first_similar = similar_result.first
          expect(first_similar).to include(:artist) if first_similar
        end
      end
    end

    context 'with invalid inputs' do
      context 'when song is not a Song instance' do
        subject(:similar_result) { song_enricher.get_similar_tracks('not_a_song') }

        it 'returns empty array' do
          expect(similar_result).to eq([])
        end
      end

      context 'when song has no artists' do
        subject(:similar_result) { song_enricher.get_similar_tracks(song_without_artists) }

        let(:song_without_artists) { create(:song, title: 'Test Song', artists: []) }

        it 'returns empty array' do
          expect(similar_result).to eq([])
        end
      end
    end

    context 'when an error occurs' do
      before do
        allow(song_enricher.instance_variable_get(:@track_finder)).to receive(:get_similar).and_raise(StandardError, 'Similar Error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        similar_result
        expect(Rails.logger).to have_received(:error).with(/Last.fm similar tracks error: Similar Error/)
      end

      it 'returns empty array' do
        expect(similar_result).to eq([])
      end
    end
  end

  describe '#get_similar_artists' do
    subject(:similar_result) { song_enricher.get_similar_artists(artist, limit: limit) }

    let(:limit) { 3 }

    context 'with valid artist' do
      it 'returns an Array' do
        expect(similar_result).to be_an(Array)
      end

      context 'when similar artists exist' do
        it 'includes name field in first result' do
          first_similar = similar_result.first
          expect(first_similar).to include(:name) if first_similar
        end
      end
    end

    context 'with invalid input' do
      context 'when artist is not an Artist instance' do
        subject(:similar_result) { song_enricher.get_similar_artists('not_an_artist') }

        it 'returns empty array' do
          expect(similar_result).to eq([])
        end
      end
    end

    context 'when an error occurs' do
      before do
        allow(song_enricher.instance_variable_get(:@artist_finder)).to receive(:get_similar).and_raise(StandardError, 'Similar Error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        similar_result
        expect(Rails.logger).to have_received(:error).with(/Last.fm similar artists error: Similar Error/)
      end

      it 'returns empty array' do
        expect(similar_result).to eq([])
      end
    end
  end

  describe 'integration test - full enrichment flow' do
    it 'enriches and returns the song' do
      result = song_enricher.enrich_song(song)
      expect(result).to eq(song)
    end

    it 'updates song lastfm_url after enrichment' do
      song_enricher.enrich_song(song)
      song.reload
      expect(song.lastfm_url).to be_present
    end

    it 'updates song lastfm_listeners after enrichment' do
      song_enricher.enrich_song(song)
      song.reload
      expect(song.lastfm_listeners).to be_a(Integer)
    end

    it 'updates song lastfm_playcount after enrichment' do
      song_enricher.enrich_song(song)
      song.reload
      expect(song.lastfm_playcount).to be_a(Integer)
    end

    it 'updates song lastfm_tags after enrichment' do
      song_enricher.enrich_song(song)
      song.reload
      expect(song.lastfm_tags).to be_an(Array)
    end

    it 'updates artist lastfm_url after enrichment' do
      song_enricher.enrich_song(song)
      artist.reload
      expect(artist.lastfm_url).to be_present
    end

    it 'updates artist lastfm_listeners after enrichment' do
      song_enricher.enrich_song(song)
      artist.reload
      expect(artist.lastfm_listeners).to be_a(Integer)
    end

    it 'updates artist lastfm_playcount after enrichment' do
      song_enricher.enrich_song(song)
      artist.reload
      expect(artist.lastfm_playcount).to be_a(Integer)
    end

    it 'updates artist lastfm_tags after enrichment' do
      song_enricher.enrich_song(song)
      artist.reload
      expect(artist.lastfm_tags).to be_an(Array)
    end

    it 'updates artist lastfm_bio after enrichment' do
      song_enricher.enrich_song(song)
      artist.reload
      expect(artist.lastfm_bio).to be_present
    end
  end
end
