# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SongImporter::Concerns::TrackFinding do
  let(:radio_station) { create(:radio_station) }
  let(:song_importer) { SongImporter.new(radio_station:) }
  let(:played_song) do
    instance_double(
      SongRecognizer,
      title: title,
      artist_name: artist_name,
      spotify_url: nil,
      isrc_code: nil,
      broadcasted_at: Time.current
    )
  end
  let(:import_logger) { instance_double(SongImportLogger, log_spotify: nil, log_deezer: nil, log_itunes: nil, log_llm: nil) }

  before do
    song_importer.instance_variable_set(:@played_song, played_song)
    song_importer.instance_variable_set(:@import_logger, import_logger)
  end

  describe 'LLM-enhanced track finding' do
    let(:title) { 'Red Lights - Radio 538 Versie' }
    let(:artist_name) { 'Dj Tiesto' }
    let(:spotify_empty_response) { { 'tracks' => { 'items' => [] } } }

    before do
      stub_request(:post, 'https://accounts.spotify.com/api/token')
        .to_return(
          status: 200,
          body: { access_token: 'test_token', token_type: 'Bearer', expires_in: 3600 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, /api\.deezer\.com/).to_return(
        status: 200, body: { 'data' => [] }.to_json, headers: { 'Content-Type' => 'application/json' }
      )
      stub_request(:get, /itunes\.apple\.com/).to_return(
        status: 200, body: { 'resultCount' => 0, 'results' => [] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    describe '#llm_import_enabled?' do
      context 'when LLM_IMPORT_ENABLED is set to false' do
        before do
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with('LLM_IMPORT_ENABLED', 'true').and_return('false')
          allow(Llm::AlternativeSearchQueries).to receive(:new)
          allow(Llm::TrackNameCleaner).to receive(:new)

          stub_request(:get, %r{api\.spotify\.com/v1/search})
            .to_return(status: 200, body: spotify_empty_response.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'skips all LLM features and returns nil', :aggregate_failures do
          song_importer.send(:track)
          expect(Llm::AlternativeSearchQueries).not_to have_received(:new)
          expect(Llm::TrackNameCleaner).not_to have_received(:new)
        end
      end
    end

    describe '#spotify_track_with_alternative_queries (Feature 5)' do
      let(:valid_spotify_response) do
        {
          'tracks' => {
            'items' => [
              build_spotify_track_item(id: 'spotify_alt', name: 'Red Lights', artist_name: 'Tiësto')
            ]
          }
        }
      end
      let(:alt_queries_double) { instance_double(Llm::AlternativeSearchQueries, raw_response: {}) }
      let(:cleaner_double) { instance_double(Llm::TrackNameCleaner, clean: nil, raw_response: {}) }

      before do
        stub_request(:get, %r{api\.spotify\.com/v1/search\?q=.*tiesto})
          .to_return(status: 200, body: spotify_empty_response.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, %r{api\.spotify\.com/v1/search\?q=.*ti%C3%ABsto})
          .to_return(status: 200, body: valid_spotify_response.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, %r{api\.spotify\.com/v1/artists/})
          .to_return(status: 200,
                     body: { 'id' => 'tiesto1', 'name' => 'Tiësto', 'images' => [] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        allow(Llm::AlternativeSearchQueries).to receive(:new).and_return(alt_queries_double)
        allow(Llm::TrackNameCleaner).to receive(:new).and_return(cleaner_double)
      end

      context 'when LLM generates alternative queries that find a match' do
        before do
          allow(alt_queries_double).to receive(:generate).and_return(
            [{ 'artist' => 'Tiësto', 'title' => 'Red Lights' }]
          )
        end

        it 'returns the alternative match' do
          expect(song_importer.send(:track)).to be_present
        end

        it 'logs the spotify result' do
          song_importer.send(:track)
          expect(import_logger).to have_received(:log_spotify).at_least(:once)
        end
      end

      context 'when LLM returns no alternatives' do
        before do
          allow(alt_queries_double).to receive(:generate).and_return([])
        end

        it 'returns nil for the track' do
          expect(song_importer.send(:track)).to be_nil
        end
      end
    end

    describe '#llm_validated_spotify_track (Feature 4)' do
      let(:spotify_result_double) do
        instance_double(
          Spotify::TrackFinder::Result,
          valid_match?: false,
          track: { 'id' => 'test' },
          matched_title_distance: 65,
          matched_artist_distance: 85,
          artists: [{ 'name' => 'Tiësto' }],
          title: 'Red Lights (Deluxe Edition Remaster)',
          spotify_query_result: { 'tracks' => { 'items' => [{ 'id' => 'test' }] } }
        )
      end
      let(:spotify_finder_double) do
        instance_double(TrackExtractor::SpotifyTrackFinder, find: spotify_result_double)
      end
      let(:validator_double) { instance_double(Llm::BorderlineMatchValidator, raw_response: {}) }
      let(:cleaner_double) { instance_double(Llm::TrackNameCleaner, clean: nil, raw_response: {}) }

      before do
        allow(TrackExtractor::SpotifyTrackFinder).to receive(:new).and_return(spotify_finder_double)
        allow(Llm::BorderlineMatchValidator).to receive(:new).and_return(validator_double)
        allow(Llm::TrackNameCleaner).to receive(:new).and_return(cleaner_double)

        stub_request(:get, /api\.deezer\.com/).to_return(
          status: 200, body: { 'data' => [] }.to_json, headers: { 'Content-Type' => 'application/json' }
        )
        stub_request(:get, /itunes\.apple\.com/).to_return(
          status: 200, body: { 'resultCount' => 0, 'results' => [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      context 'when the match has borderline title similarity and LLM confirms' do
        before do
          allow(validator_double).to receive(:same_song?).and_return(true)
        end

        it 'returns the borderline match' do
          expect(song_importer.send(:spotify_track_if_valid)).to eq(spotify_result_double)
        end
      end

      context 'when the match has borderline title similarity and LLM rejects' do
        before do
          allow(validator_double).to receive(:same_song?).and_return(false)
        end

        it 'returns nil' do
          expect(song_importer.send(:spotify_track_if_valid)).to be_nil
        end
      end
    end

    describe '#llm_cleaned_track (Feature 1)' do
      let(:cleaned_spotify_response) do
        {
          'tracks' => {
            'items' => [
              build_spotify_track_item(id: 'spotify_cleaned', name: 'Red Lights', artist_name: 'Tiësto')
            ]
          }
        }
      end
      let(:alt_queries_double) { instance_double(Llm::AlternativeSearchQueries, generate: [], raw_response: {}) }
      let(:cleaner_double) { instance_double(Llm::TrackNameCleaner, raw_response: {}) }

      before do
        stub_request(:get, %r{api\.spotify\.com/v1/search\?q=.*tiesto})
          .to_return(status: 200, body: spotify_empty_response.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, %r{api\.spotify\.com/v1/search\?q=.*ti%C3%ABsto})
          .to_return(status: 200, body: cleaned_spotify_response.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, %r{api\.spotify\.com/v1/artists/})
          .to_return(status: 200,
                     body: { 'id' => 'tiesto1', 'name' => 'Tiësto', 'images' => [] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        allow(Llm::AlternativeSearchQueries).to receive(:new).and_return(alt_queries_double)
        allow(Llm::TrackNameCleaner).to receive(:new).and_return(cleaner_double)
      end

      context 'when LLM cleans the track name and retry succeeds' do
        before do
          allow(cleaner_double).to receive(:clean).and_return(
            { 'artist' => 'Tiësto', 'title' => 'Red Lights' }
          )
        end

        it 'returns the cleaned match' do
          expect(song_importer.send(:track)).to be_present
        end

        it 'logs the spotify result' do
          song_importer.send(:track)
          expect(import_logger).to have_received(:log_spotify).at_least(:once)
        end
      end

      context 'when LLM cleanup returns nil' do
        before do
          allow(cleaner_double).to receive(:clean).and_return(nil)
        end

        it 'returns nil' do
          expect(song_importer.send(:track)).to be_nil
        end
      end

      context 'when cleaned direct search fails but alternative queries with cleaned names succeed' do
        let(:title) { '785 Fundament' }
        let(:artist_name) { 'Opwekking Band met Marcel Zimmer' }

        before do
          allow(cleaner_double).to receive(:clean).and_return(
            { 'artist' => 'Opwekking Band met Marcel Zimmer', 'title' => 'Fundament' }
          )

          # First call: alternative queries for original names (returns nothing)
          # Second call: alternative queries for cleaned names (returns simplified artist)
          alt_queries_cleaned = instance_double(Llm::AlternativeSearchQueries, raw_response: {})
          allow(alt_queries_cleaned).to receive(:generate).and_return(
            [{ 'artist' => 'Opwekking', 'title' => 'Fundament' }]
          )
          allow(Llm::AlternativeSearchQueries).to receive(:new)
                                                    .with(artist_name: artist_name, title: title).and_return(alt_queries_double)
          allow(Llm::AlternativeSearchQueries).to receive(:new)
                                                    .with(artist_name: 'Opwekking Band met Marcel Zimmer', title: 'Fundament')
                                                    .and_return(alt_queries_cleaned)

          # All searches with the full artist name return empty
          stub_request(:get, %r{api\.spotify\.com/v1/search\?q=.*opwekking%20band})
            .to_return(status: 200, body: spotify_empty_response.to_json,
                       headers: { 'Content-Type' => 'application/json' })

          # Simplified "Opwekking" search returns a result
          opwekking_response = {
            'tracks' => {
              'items' => [
                build_spotify_track_item(id: 'spotify_opw', name: 'Fundament', artist_name: 'Opwekking')
              ]
            }
          }
          stub_request(:get, %r{api\.spotify\.com/v1/search\?q=.*artist.opwekking&type=track})
            .to_return(status: 200, body: opwekking_response.to_json,
                       headers: { 'Content-Type' => 'application/json' })

          stub_request(:get, %r{api\.spotify\.com/v1/artists/})
            .to_return(status: 200,
                       body: { 'id' => 'opw1', 'name' => 'Opwekking', 'images' => [] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'finds the track via second-round alternative queries' do
          expect(song_importer.send(:track)).to be_present
        end
      end
    end

    describe '#worth_llm_cleanup?' do
      context 'when Spotify found results with reasonable similarity' do
        let(:title) { 'Slapeloze Nachten' }
        let(:artist_name) { 'Opposites' }
        let(:spotify_result_double) do
          instance_double(
            Spotify::TrackFinder::Result,
            valid_match?: false,
            track: { 'id' => 'test' },
            matched_title_distance: 100,
            matched_artist_distance: 78,
            artists: [{ 'name' => 'The Opposites' }],
            title: 'Slapeloze Nachten',
            spotify_query_result: { 'tracks' => { 'items' => [{ 'id' => 'test' }] } }
          )
        end
        let(:spotify_finder_double) do
          instance_double(TrackExtractor::SpotifyTrackFinder, find: spotify_result_double)
        end
        let(:cleaner_double) { instance_double(Llm::TrackNameCleaner, clean: nil, raw_response: {}) }

        before do
          allow(TrackExtractor::SpotifyTrackFinder).to receive(:new).and_return(spotify_finder_double)
          allow(Llm::TrackNameCleaner).to receive(:new).and_return(cleaner_double)
          stub_request(:get, /api\.deezer\.com/).to_return(
            status: 200, body: { 'data' => [] }.to_json, headers: { 'Content-Type' => 'application/json' }
          )
          stub_request(:get, /itunes\.apple\.com/).to_return(
            status: 200, body: { 'resultCount' => 0, 'results' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        end

        it 'skips LLM cleanup' do
          song_importer.send(:track)
          expect(Llm::TrackNameCleaner).not_to have_received(:new)
        end
      end

      context 'when Spotify found results but names have cleanup patterns' do
        let(:title) { 'Red Lights (Radio 538 Versie)' }
        let(:artist_name) { 'Dj Tiesto' }
        let(:spotify_result_double) do
          instance_double(
            Spotify::TrackFinder::Result,
            valid_match?: false,
            track: { 'id' => 'test' },
            matched_title_distance: 55,
            matched_artist_distance: 75,
            artists: [{ 'name' => 'Tiësto' }],
            title: 'Red Lights',
            spotify_query_result: { 'tracks' => { 'items' => [{ 'id' => 'test' }] } }
          )
        end
        let(:spotify_finder_double) do
          instance_double(TrackExtractor::SpotifyTrackFinder, find: spotify_result_double)
        end
        let(:cleaner_double) { instance_double(Llm::TrackNameCleaner, clean: nil, raw_response: {}) }

        before do
          allow(TrackExtractor::SpotifyTrackFinder).to receive(:new).and_return(spotify_finder_double)
          allow(Llm::TrackNameCleaner).to receive(:new).and_return(cleaner_double)
          stub_request(:get, /api\.deezer\.com/).to_return(
            status: 200, body: { 'data' => [] }.to_json, headers: { 'Content-Type' => 'application/json' }
          )
          stub_request(:get, /itunes\.apple\.com/).to_return(
            status: 200, body: { 'resultCount' => 0, 'results' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        end

        it 'proceeds with LLM cleanup' do
          song_importer.send(:track)
          expect(Llm::TrackNameCleaner).to have_received(:new)
        end
      end
    end
  end

  private

  def build_spotify_track_item(id:, name:, artist_name:, popularity: 70)
    {
      'id' => id,
      'name' => name,
      'popularity' => popularity,
      'duration_ms' => 210_000,
      'explicit' => false,
      'album' => {
        'artists' => [{ 'id' => "#{id}_artist", 'name' => artist_name }],
        'album_type' => 'single',
        'images' => [{ 'url' => 'https://example.com/image.jpg' }],
        'release_date' => '2014-01-01',
        'release_date_precision' => 'day',
        'name' => name
      },
      'artists' => [{ 'id' => "#{id}_artist", 'name' => artist_name }],
      'external_ids' => { 'isrc' => 'NL1234' },
      'external_urls' => { 'spotify' => "https://open.spotify.com/track/#{id}" },
      'preview_url' => nil
    }
  end
end
