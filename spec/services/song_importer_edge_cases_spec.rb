# frozen_string_literal: true

describe SongImporter do
  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }
  let(:import_logger) do
    instance_double(SongImportLogger, start_log: nil, log_scraping: nil, skip_log: nil,
                                      complete_log: nil, log_recognition: nil, log_acoustid: nil,
                                      fail_log: nil, log_spotify: nil, log_deezer: nil, log_itunes: nil,
                                      log_llm: nil)
  end

  before do
    allow(SongImportLogger).to receive(:new).and_return(import_logger)
  end

  describe '#import edge cases' do
    let(:station) { create(:radio_station, url: 'https://example.com/api', processor: 'npo_api_processor') }
    let(:importer) { described_class.new(radio_station: station) }

    describe 'blank artist name handling' do
      let(:scraper) do
        instance_double(
          TrackScraper::NpoApiProcessor,
          last_played_song: true,
          title: 'Some Song',
          artist_name: '',
          spotify_url: nil,
          isrc_code: nil,
          broadcasted_at: Time.current,
          raw_response: {},
          is_a?: false
        )
      end

      before do
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_return(scraper)
        allow(Broadcaster).to receive(:no_importing_artists)
      end

      it 'returns false and skips import', :aggregate_failures do
        result = importer.import
        expect(result).to be false
        expect(Broadcaster).to have_received(:no_importing_artists)
      end
    end

    describe 'nil artist name handling' do
      let(:scraper) do
        instance_double(
          TrackScraper::NpoApiProcessor,
          last_played_song: true,
          title: 'Some Song',
          artist_name: nil,
          spotify_url: nil,
          isrc_code: nil,
          broadcasted_at: Time.current,
          raw_response: {},
          is_a?: false
        )
      end

      before do
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_return(scraper)
        allow(Broadcaster).to receive(:no_importing_artists)
      end

      it 'returns false and skips import', :aggregate_failures do
        result = importer.import
        expect(result).to be false
        expect(Broadcaster).to have_received(:no_importing_artists)
      end
    end

    describe 'artist extraction returns nil' do
      let(:scraper) do
        instance_double(
          TrackScraper::NpoApiProcessor,
          last_played_song: true,
          title: 'Valid Title',
          artist_name: 'Valid Artist',
          spotify_url: nil,
          isrc_code: nil,
          broadcasted_at: Time.current,
          raw_response: {},
          is_a?: false
        )
      end

      let(:artists_extractor) { instance_double(TrackExtractor::ArtistsExtractor, extract: nil) }

      before do
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_return(scraper)
        allow(Broadcaster).to receive(:no_artists_or_song)
        allow(TrackExtractor::ArtistsExtractor).to receive(:new).and_return(artists_extractor)
        allow(importer).to receive(:track).and_return(nil)
      end

      it 'returns false when artists extraction fails', :aggregate_failures do
        result = importer.import
        expect(result).to be false
        expect(Broadcaster).to have_received(:no_artists_or_song)
      end
    end

    describe 'song extraction returns nil' do
      let(:scraper) do
        instance_double(
          TrackScraper::NpoApiProcessor,
          last_played_song: true,
          title: 'Valid Title',
          artist_name: 'Valid Artist',
          spotify_url: nil,
          isrc_code: nil,
          broadcasted_at: Time.current,
          raw_response: {},
          is_a?: false
        )
      end

      before do
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_return(scraper)
        allow(Broadcaster).to receive(:no_artists_or_song)
        allow(importer).to receive_messages(artists: [artist], song: nil)
      end

      it 'returns false when song extraction fails', :aggregate_failures do
        result = importer.import
        expect(result).to be false
        expect(Broadcaster).to have_received(:no_artists_or_song)
      end
    end

    describe 'StandardError during import' do
      let(:scraper) do
        instance_double(
          TrackScraper::NpoApiProcessor,
          last_played_song: true,
          title: 'Valid Title',
          artist_name: 'Valid Artist',
          spotify_url: nil,
          isrc_code: nil,
          broadcasted_at: Time.current,
          raw_response: {},
          is_a?: false
        )
      end

      before do
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_return(scraper)
        allow(importer).to receive_messages(artists: [artist], song:)
        allow(importer).to receive(:deezer_track).and_raise(StandardError, 'API connection failed')
        allow(ExceptionNotifier).to receive(:notify)
        allow(Broadcaster).to receive(:error_during_import)
      end

      it 'rescues the error and returns nil', :aggregate_failures do
        result = importer.import
        expect(result).to be_nil
        expect(ExceptionNotifier).to have_received(:notify)
        expect(Broadcaster).to have_received(:error_during_import)
      end

      it 'logs the failure' do
        importer.import
        expect(import_logger).to have_received(:fail_log).with(reason: 'API connection failed')
      end
    end

    describe 'instance variable cleanup after import' do
      let(:scraper) do
        instance_double(
          TrackScraper::NpoApiProcessor,
          last_played_song: true,
          title: 'First Song',
          artist_name: 'First Artist',
          spotify_url: nil,
          isrc_code: nil,
          broadcasted_at: Time.current,
          raw_response: {},
          is_a?: false
        )
      end

      before do
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_return(scraper)
        allow(Broadcaster).to receive(:no_artists_or_song)
        allow(importer).to receive_messages(artists: nil, song: nil)
      end

      it 'clears instance variables after import completes' do
        importer.import
        expect(importer.instance_variable_get(:@played_song)).to be_nil
      end

      it 'clears instance variables even after error' do
        allow(importer).to receive(:scrape_song).and_raise(StandardError, 'test')
        allow(ExceptionNotifier).to receive(:notify)
        allow(Broadcaster).to receive(:error_during_import)
        importer.import
        expect(importer.instance_variable_get(:@played_song)).to be_nil
      end
    end

    describe 'safe_start_log error handling' do
      before do
        allow(import_logger).to receive(:start_log).and_raise(StandardError, 'DB connection lost')
        allow(Rails.logger).to receive(:error)
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_return(
          instance_double(TrackScraper::NpoApiProcessor, last_played_song: nil)
        )
        allow(importer).to receive(:recognize_song).and_return(nil)
        allow(Broadcaster).to receive(:no_importing_song)
      end

      it 'continues import even when start_log fails' do
        result = importer.import
        expect(result).to be false
      end

      it 'logs the error' do
        importer.import
        expect(Rails.logger).to have_received(:error).with(/Failed to create song import log/)
      end
    end
  end

  describe '#recently_imported?' do
    let(:station) { create(:radio_station, url: 'https://example.com/api', processor: 'slam_api_processor') }
    let(:importer) { described_class.new(radio_station: station) }
    let(:broadcasted_at) { Time.zone.parse('2026-04-14 13:32:25') }
    let(:scraper) do
      instance_double(
        TrackScraper::SlamApiProcessor,
        last_played_song: true,
        title: 'Housuh In De Pauzuh',
        artist_name: 'SLAM!',
        spotify_url: nil,
        isrc_code: nil,
        broadcasted_at: broadcasted_at,
        raw_response: {}
      )
    end

    before do
      allow(TrackScraper::SlamApiProcessor).to receive(:new).and_return(scraper)
      allow(scraper).to receive(:is_a?).with(TrackScraper).and_return(true)
      allow(import_logger).to receive(:log).and_return(build(:song_import_log, id: 999_999))
    end

    context 'when a recent import log with same data exists' do
      before do
        create(:song_import_log, radio_station: station, scraped_artist: 'SLAM!',
                                 scraped_title: 'Housuh In De Pauzuh', broadcasted_at: broadcasted_at,
                                 created_at: 10.minutes.ago)
      end

      it 'skips the import', :aggregate_failures do
        result = importer.import
        expect(result).to be false
        expect(import_logger).to have_received(:skip_log).with(reason: /Duplicate/)
      end
    end

    context 'when no recent import log with same data exists' do
      before do
        allow(Broadcaster).to receive(:no_artists_or_song)
        allow(importer).to receive_messages(track: nil, artists: nil)
      end

      it 'does not skip for duplicate reasons' do
        importer.import
        expect(import_logger).not_to have_received(:skip_log).with(reason: /Duplicate/)
      end
    end
  end

  describe '#radio_program?' do
    let(:station) { create(:radio_station, name: 'SLAM!', url: 'https://example.com/api', processor: 'slam_api_processor') }
    let(:importer) { described_class.new(radio_station: station) }
    let(:scraper) do
      instance_double(
        TrackScraper::SlamApiProcessor,
        last_played_song: true,
        title: title,
        artist_name: artist_name,
        spotify_url: nil,
        isrc_code: nil,
        broadcasted_at: Time.current,
        raw_response: {}
      )
    end
    let(:detector_double) { instance_double(Llm::ProgramDetector, raw_response: {}) }

    before do
      allow(TrackScraper::SlamApiProcessor).to receive(:new).and_return(scraper)
      allow(scraper).to receive(:is_a?).with(TrackScraper).and_return(true)
      allow(import_logger).to receive(:log).and_return(build(:song_import_log, id: 999_999))
      allow(importer).to receive(:track).and_return(nil)
      allow(Llm::ProgramDetector).to receive(:new).and_return(detector_double)
    end

    context 'when artist matches station name and LLM confirms program' do
      let(:artist_name) { 'SLAM!' }
      let(:title) { 'Housuh In De Pauzuh' }

      before do
        allow(detector_double).to receive(:program?).and_return(true)
      end

      it 'skips the import', :aggregate_failures do
        result = importer.import
        expect(result).to be false
        expect(import_logger).to have_received(:skip_log).with(reason: /radio program/)
      end
    end

    context 'when artist matches station name but LLM says it is a song' do
      let(:artist_name) { 'SLAM!' }
      let(:title) { 'Some Actual Song' }

      before do
        allow(detector_double).to receive(:program?).and_return(false)
        allow(Broadcaster).to receive(:no_artists_or_song)
        allow(importer).to receive(:artists).and_return(nil)
      end

      it 'does not skip for program detection' do
        importer.import
        expect(import_logger).not_to have_received(:skip_log).with(reason: /radio program/)
      end
    end

    context 'when artist does not resemble station name' do
      let(:artist_name) { 'Tiësto' }
      let(:title) { 'Red Lights' }

      before do
        allow(Broadcaster).to receive(:no_artists_or_song)
        allow(importer).to receive(:artists).and_return(nil)
      end

      it 'does not call the LLM program detector' do
        importer.import
        expect(Llm::ProgramDetector).not_to have_received(:new)
      end
    end

    context 'when track finding returns a Spotify match' do
      let(:artist_name) { 'SLAM!' }
      let(:title) { 'Some Song' }
      let(:valid_track) { instance_double(Spotify::TrackFinder::Result, valid_match?: true) }

      before do
        allow(Broadcaster).to receive(:no_artists_or_song)
        allow(importer).to receive_messages(track: valid_track, artists: nil)
      end

      it 'does not check for radio program' do
        importer.import
        expect(Llm::ProgramDetector).not_to have_received(:new)
      end
    end
  end

  describe '#artist_resembles_station?' do
    let(:importer) { described_class.new(radio_station:) }

    before do
      allow(importer).to receive(:artist_name).and_return(artist_name)
    end

    {
      'exact match' => { station: 'SLAM!', artist: 'SLAM!', expected: true },
      'case insensitive' => { station: 'SLAM!', artist: 'Slam!', expected: true },
      'station in artist' => { station: 'Radio 538', artist: '538', expected: true },
      'artist in station' => { station: 'Groot Nieuws Radio', artist: 'GNR', expected: false },
      'no resemblance' => { station: 'SLAM!', artist: 'Tiësto', expected: false }
    }.each do |label, params|
      context "with #{label}" do
        let(:radio_station) { create(:radio_station, name: params[:station]) }
        let(:artist_name) { params[:artist] }

        it "returns #{params[:expected]}" do
          expect(importer.send(:artist_resembles_station?)).to eq(params[:expected])
        end
      end
    end
  end

  describe '#illegal_word_in_title' do
    let(:importer) { described_class.new(radio_station:) }

    before do
      allow(importer).to receive(:title).and_return(title_text)
    end

    {
      'title with reklame' => true,
      'REKLAME block' => true,
      'Reclame' => true,
      'nieuws update' => true,
      'NIEUWS' => true,
      'pingel sound' => true,
      "title with ''" => true,
      "title with '''" => true,
      'title with ..' => true,
      'title with ...' => true,
      'Normal Song Title' => false,
      "It's a normal title" => false,
      '3.14 is pi' => false,
      "Song with 'quotes'" => false
    }.each do |title_text, expected|
      context "with title '#{title_text}'" do
        let(:title_text) { title_text }

        it "returns #{expected}" do
          expect(importer.send(:illegal_word_in_title)).to eq(expected)
        end
      end
    end
  end

  describe '#create_air_play edge cases' do
    let(:importer) { described_class.new(radio_station:) }

    before do
      importer.instance_variable_set(:@song, song)
      importer.instance_variable_set(:@artists, [artist])
      importer.instance_variable_set(:@played_song, instance_double(SongRecognizer, is_a?: false))
      importer.instance_variable_set(:@broadcasted_at, Time.current)
    end

    describe 'when song was already imported recently' do
      before do
        air_play = create(:air_play, radio_station:, song:, broadcasted_at: 10.minutes.ago, created_at: 10.minutes.ago)
        radio_station.update(last_added_air_play_ids: [air_play.id])
        allow(Broadcaster).to receive(:last_song)
      end

      it 'does not create a new air play' do
        expect { importer.send(:create_air_play) }.not_to change(AirPlay, :count)
      end

      it 'logs the skip reason' do
        importer.send(:create_air_play)
        expect(import_logger).to have_received(:skip_log).with(reason: /already imported recently/)
      end
    end

    describe 'draft confirmation with same song' do
      let(:broadcasted_at) { Time.current }
      let!(:draft) do
        create(:air_play, :draft, radio_station:, song:,
                                  broadcasted_at: broadcasted_at - 2.minutes)
      end

      before do
        importer.instance_variable_set(:@broadcasted_at, broadcasted_at)
        allow(SongImporter::RecognizerImporter).to receive(:new).and_return(
          instance_double(SongImporter::RecognizerImporter, may_import_song?: true)
        )
        allow(Broadcaster).to receive(:song_confirmed)
        allow(MusicProfileJob).to receive(:perform_async)
        allow(SongExternalIdsEnrichmentJob).to receive(:perform_async)
      end

      it 'confirms the existing draft air play' do
        importer.send(:create_air_play)
        expect(draft.reload.status).to eq('confirmed')
      end
    end

    describe 'new air play creation with auto-confirm for scraper imports' do
      before do
        importer.instance_variable_set(:@scraper_import, true)
        allow(SongImporter::ScraperImporter).to receive(:new).and_return(
          instance_double(SongImporter::ScraperImporter, may_import_song?: true)
        )
        allow(Broadcaster).to receive(:song_confirmed)
        allow(MusicProfileJob).to receive(:perform_async)
        allow(SongExternalIdsEnrichmentJob).to receive(:perform_async)
      end

      it 'creates a confirmed air play' do
        expect { importer.send(:create_air_play) }.to change(AirPlay.confirmed, :count).by(1)
      end
    end

    describe 'new air play creation as draft for recognizer with processor' do
      let(:station_with_processor) { create(:radio_station, processor: 'npo_api_processor') }
      let(:rec_importer) { described_class.new(radio_station: station_with_processor) }

      before do
        allow(SongImportLogger).to receive(:new).and_return(import_logger)
        rec_importer.instance_variable_set(:@song, song)
        rec_importer.instance_variable_set(:@artists, [artist])
        rec_importer.instance_variable_set(:@played_song, instance_double(SongRecognizer, is_a?: false))
        rec_importer.instance_variable_set(:@scraper_import, false)
        rec_importer.instance_variable_set(:@broadcasted_at, Time.current)
        allow(SongImporter::RecognizerImporter).to receive(:new).and_return(
          instance_double(SongImporter::RecognizerImporter, may_import_song?: true)
        )
        allow(Broadcaster).to receive(:song_draft_created)
        allow(MusicProfileJob).to receive(:perform_async)
        allow(SongExternalIdsEnrichmentJob).to receive(:perform_async)
      end

      it 'creates a draft air play' do
        expect { rec_importer.send(:create_air_play) }.to change(AirPlay.draft, :count).by(1)
      end
    end
  end

  describe '#finalize_song_import edge cases' do
    let(:importer) { described_class.new(radio_station:) }
    let(:air_play) { create(:air_play, radio_station:, song:, broadcasted_at: Time.current) }

    before do
      importer.instance_variable_set(:@song, song)
      importer.instance_variable_set(:@artists, [artist])
      allow(MusicProfileJob).to receive(:perform_async)
      allow(SongExternalIdsEnrichmentJob).to receive(:perform_async)
    end

    it 'enqueues MusicProfileJob and SongExternalIdsEnrichmentJob', :aggregate_failures do
      importer.send(:finalize_song_import, air_play)
      expect(MusicProfileJob).to have_received(:perform_async).with(song.id, radio_station.id)
      expect(SongExternalIdsEnrichmentJob).to have_received(:perform_async).with(song.id)
    end

    it 'updates the radio station last_added_air_play_ids' do
      importer.send(:finalize_song_import, air_play)
      expect(radio_station.reload.last_added_air_play_ids).to include(air_play.id)
    end

    it 'does not duplicate RadioStationSong when association already exists' do
      create(:radio_station_song, radio_station:, song:)
      expect { importer.send(:finalize_song_import, air_play) }.not_to change(RadioStationSong, :count)
    end

    it 'creates RadioStationSong when association does not exist' do
      expect { importer.send(:finalize_song_import, air_play) }.to change(RadioStationSong, :count).by(1)
    end
  end

  describe 'Matcher boundary conditions' do
    describe 'one hour time boundary' do
      let(:matcher) { SongImporter::Matcher.new(radio_station:, song:) }

      context 'when song was played exactly 59 minutes ago' do
        before do
          create(:air_play, radio_station:, song:, created_at: 59.minutes.ago)
        end

        it 'matches (within the 1 hour window)' do
          expect(matcher.matches_any_played_last_hour?).to be true
        end
      end

      context 'when song was played exactly 61 minutes ago' do
        before do
          create(:air_play, radio_station:, song:, created_at: 61.minutes.ago)
        end

        it 'does not match (outside the 1 hour window)' do
          expect(matcher.matches_any_played_last_hour?).to be false
        end
      end
    end

    describe 'similarity threshold boundaries' do
      let(:matcher) { SongImporter::Matcher.new(radio_station:, song:) }

      context 'when title is similar but just below threshold' do
        # Need very different strings so JaroWinkler < 0.70
        let(:below_threshold_song) { create(:song, title: 'Waterfall Dreams', artists: [artist]) }

        before do
          create(:air_play, radio_station:, song: below_threshold_song, created_at: 30.minutes.ago)
        end

        it 'does not match because title similarity is below 70' do
          expect(matcher.matches_any_played_last_hour?).to be false
        end
      end

      context 'when artist matches but title is completely different' do
        let(:different_title_song) { create(:song, title: 'Xyztuvw Abcdefg', artists: [artist]) }

        before do
          create(:air_play, radio_station:, song: different_title_song, created_at: 30.minutes.ago)
        end

        it 'does not match despite artist matching' do
          expect(matcher.matches_any_played_last_hour?).to be false
        end
      end
    end

    describe 'unicode and special characters' do
      context 'when song titles contain unicode' do
        let(:unicode_artist) { create(:artist, name: 'Björk') }
        let(:unicode_song) { create(:song, title: 'Jóga', artists: [unicode_artist]) }
        let(:matcher) { SongImporter::Matcher.new(radio_station:, song: unicode_song) }

        before do
          create(:air_play, radio_station:, song: unicode_song, created_at: 30.minutes.ago)
        end

        it 'matches unicode titles correctly' do
          expect(matcher.matches_any_played_last_hour?).to be true
        end
      end

      context 'when song titles contain parenthetical info' do
        let(:base_song) { create(:song, title: 'Stay', artists: [artist]) }
        let(:feat_song) { create(:song, title: 'Stay (feat. Justin Bieber)', artists: [artist]) }
        let(:matcher) { SongImporter::Matcher.new(radio_station:, song: base_song) }

        before do
          create(:air_play, radio_station:, song: feat_song, created_at: 30.minutes.ago)
        end

        it 'has reduced similarity due to parenthetical suffix', :aggregate_failures do
          score = matcher.title_match(feat_song)
          # "Stay" vs "Stay (feat. Justin Bieber)" - JaroWinkler gives partial credit
          expect(score).to be > 0
          expect(score).to be < 100
        end
      end
    end

    describe 'station isolation' do
      let(:other_station) { create(:radio_station) }
      let(:matcher) { SongImporter::Matcher.new(radio_station:, song:) }

      before do
        # Song played on a different station
        create(:air_play, radio_station: other_station, song:, created_at: 30.minutes.ago)
      end

      it 'does not match songs from other stations' do
        expect(matcher.matches_any_played_last_hour?).to be false
      end
    end
  end

  describe 'ScraperImporter edge cases' do
    let(:other_song) { create(:song, title: 'Other Song', artists: [artist]) }

    describe 'when scraper_import flag differs on air plays' do
      subject(:scraper_importer) do
        SongImporter::ScraperImporter.new(radio_station:, artists: [artist], song:)
      end

      context 'when last air play is recognizer import, not scraper' do
        before do
          create(:air_play, radio_station:, song:, scraper_import: false,
                            broadcasted_at: 5.minutes.ago, created_at: 5.minutes.ago)
        end

        it 'returns false because the song still matches in the last hour' do
          # not_last_added_song is true (no scraper imports), but any_song_matches? is true
          expect(scraper_importer.may_import_song?).to be false
        end
      end

      context 'when scraper and recognizer imports interleaved' do
        before do
          create(:air_play, radio_station:, song: other_song, scraper_import: true,
                            broadcasted_at: 30.minutes.ago, created_at: 30.minutes.ago)
          create(:air_play, radio_station:, song:, scraper_import: false,
                            broadcasted_at: 15.minutes.ago, created_at: 15.minutes.ago)
        end

        it 'compares only against the latest scraper import' do
          # Last scraper import is other_song, so not_last_added_song = true
          # But song was played 15 min ago via recognizer, so any_song_matches? = true
          expect(scraper_importer.may_import_song?).to be false
        end
      end
    end
  end

  describe 'RecognizerImporter edge cases' do
    describe 'when last_added_air_play_ids is empty array' do
      subject(:recognizer_importer) do
        SongImporter::RecognizerImporter.new(radio_station:, artists: [artist], song:)
      end

      before do
        radio_station.update(last_added_air_play_ids: [])
      end

      it 'returns true since there is no last played song' do
        expect(recognizer_importer.may_import_song?).to be true
      end
    end

    describe 'when last_added_air_play_ids references deleted air play' do
      subject(:recognizer_importer) do
        SongImporter::RecognizerImporter.new(radio_station:, artists: [artist], song:)
      end

      before do
        radio_station.update(last_added_air_play_ids: [999_999_999])
      end

      it 'returns true since the air play no longer exists' do
        expect(recognizer_importer.may_import_song?).to be true
      end
    end
  end

  describe 'track finding edge cases' do
    let(:importer) { described_class.new(radio_station:) }
    let(:played_song) do
      instance_double(
        SongRecognizer,
        title: 'Some Song',
        artist_name: 'Some Artist',
        spotify_url: nil,
        isrc_code: nil,
        broadcasted_at: Time.current
      )
    end

    before do
      importer.instance_variable_set(:@played_song, played_song)
    end

    describe 'when all track finders return nil' do
      let(:spotify_finder) { instance_double(TrackExtractor::SpotifyTrackFinder, find: nil) }
      let(:itunes_finder) { instance_double(TrackExtractor::ItunesTrackFinder, find: nil) }
      let(:deezer_finder) { instance_double(TrackExtractor::DeezerTrackFinder, find: nil) }

      before do
        allow(TrackExtractor::SpotifyTrackFinder).to receive(:new).and_return(spotify_finder)
        allow(TrackExtractor::ItunesTrackFinder).to receive(:new).and_return(itunes_finder)
        allow(TrackExtractor::DeezerTrackFinder).to receive(:new).and_return(deezer_finder)
      end

      it 'returns nil for track' do
        expect(importer.send(:track)).to be_nil
      end
    end

    describe 'when all track finders return invalid matches' do
      let(:invalid_spotify) do
        instance_double(Spotify::TrackFinder::Result, valid_match?: false, track: { 'id' => 'x' },
                                                      matched_title_distance: 50, matched_artist_distance: 50,
                                                      spotify_query_result: { 'tracks' => { 'items' => [{}] } })
      end
      let(:invalid_itunes) { instance_double(Itunes::TrackFinder::Result, valid_match?: false) }
      let(:invalid_deezer) { instance_double(Deezer::TrackFinder::Result, valid_match?: false) }
      let(:spotify_finder) { instance_double(TrackExtractor::SpotifyTrackFinder, find: invalid_spotify) }
      let(:itunes_finder) { instance_double(TrackExtractor::ItunesTrackFinder, find: invalid_itunes) }
      let(:deezer_finder) { instance_double(TrackExtractor::DeezerTrackFinder, find: invalid_deezer) }
      let(:cleaner_double) { instance_double(Llm::TrackNameCleaner, clean: nil, raw_response: {}) }

      before do
        allow(TrackExtractor::SpotifyTrackFinder).to receive(:new).and_return(spotify_finder)
        allow(TrackExtractor::ItunesTrackFinder).to receive(:new).and_return(itunes_finder)
        allow(TrackExtractor::DeezerTrackFinder).to receive(:new).and_return(deezer_finder)
        allow(Llm::TrackNameCleaner).to receive(:new).and_return(cleaner_double)
      end

      it 'returns nil when no track has a valid match' do
        expect(importer.send(:track)).to be_nil
      end
    end

    describe 'when Spotify fails but iTunes succeeds' do
      let(:valid_itunes) { instance_double(Itunes::TrackFinder::Result, valid_match?: true) }
      let(:spotify_finder) { instance_double(TrackExtractor::SpotifyTrackFinder, find: nil) }
      let(:itunes_finder) { instance_double(TrackExtractor::ItunesTrackFinder, find: valid_itunes) }

      before do
        allow(TrackExtractor::SpotifyTrackFinder).to receive(:new).and_return(spotify_finder)
        allow(TrackExtractor::ItunesTrackFinder).to receive(:new).and_return(itunes_finder)
      end

      it 'returns the iTunes track' do
        expect(importer.send(:track)).to eq(valid_itunes)
      end
    end

    describe 'when Spotify invalid, iTunes invalid, Deezer valid' do
      let(:invalid_spotify) do
        instance_double(Spotify::TrackFinder::Result, valid_match?: false, track: { 'id' => 'x' },
                                                      matched_title_distance: 50, matched_artist_distance: 50,
                                                      spotify_query_result: { 'tracks' => { 'items' => [{}] } })
      end
      let(:invalid_itunes) { instance_double(Itunes::TrackFinder::Result, valid_match?: false) }
      let(:valid_deezer) { instance_double(Deezer::TrackFinder::Result, valid_match?: true) }
      let(:spotify_finder) { instance_double(TrackExtractor::SpotifyTrackFinder, find: invalid_spotify) }
      let(:itunes_finder) { instance_double(TrackExtractor::ItunesTrackFinder, find: invalid_itunes) }
      let(:deezer_finder) { instance_double(TrackExtractor::DeezerTrackFinder, find: valid_deezer) }

      before do
        allow(TrackExtractor::SpotifyTrackFinder).to receive(:new).and_return(spotify_finder)
        allow(TrackExtractor::ItunesTrackFinder).to receive(:new).and_return(itunes_finder)
        allow(TrackExtractor::DeezerTrackFinder).to receive(:new).and_return(deezer_finder)
      end

      it 'falls back to Deezer as the last resort' do
        expect(importer.send(:track)).to eq(valid_deezer)
      end
    end

    describe 'track finding memoization' do
      let(:valid_spotify) { instance_double(Spotify::TrackFinder::Result, valid_match?: true) }
      let(:spotify_finder) { instance_double(TrackExtractor::SpotifyTrackFinder, find: valid_spotify) }

      before do
        allow(TrackExtractor::SpotifyTrackFinder).to receive(:new).and_return(spotify_finder)
      end

      it 'returns the same track object on subsequent calls' do
        first = importer.send(:track)
        second = importer.send(:track)
        expect(first).to equal(second)
      end
    end
  end

  describe '#scrape_song edge cases' do
    describe 'when processor is blank' do
      let(:station) { create(:radio_station, url: 'https://example.com', processor: '') }
      let(:importer) { described_class.new(radio_station: station) }

      it 'returns nil without attempting to scrape' do
        expect(importer.send(:scrape_song)).to be_nil
      end
    end

    describe 'when url is blank' do
      let(:station) { create(:radio_station, url: '', processor: 'npo_api_processor') }
      let(:importer) { described_class.new(radio_station: station) }

      it 'returns nil without attempting to scrape' do
        expect(importer.send(:scrape_song)).to be_nil
      end
    end

    describe 'when scraper raises an error' do
      let(:station) { create(:radio_station, url: 'https://example.com/api', processor: 'npo_api_processor') }
      let(:importer) { described_class.new(radio_station: station) }

      before do
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_raise(StandardError, 'API timeout')
      end

      it 'propagates the error to be caught by the rescue in #import' do
        expect { importer.send(:scrape_song) }.to raise_error(StandardError, 'API timeout')
      end
    end

    describe 'when scraper last_played_song returns false (not nil)' do
      let(:station) { create(:radio_station, url: 'https://example.com/api', processor: 'npo_api_processor') }
      let(:importer) { described_class.new(radio_station: station) }
      let(:scraper) { instance_double(TrackScraper::NpoApiProcessor, last_played_song: false) }

      before do
        allow(TrackScraper::NpoApiProcessor).to receive(:new).and_return(scraper)
      end

      it 'returns nil because last_played_song is falsey' do
        expect(importer.send(:scrape_song)).to be_nil
      end
    end
  end

  describe 'AirPlay.find_draft_for_confirmation edge cases' do
    describe 'when broadcasted_at is nil' do
      it 'returns nil' do
        expect(AirPlay.find_draft_for_confirmation(radio_station, song, nil)).to be_nil
      end
    end

    describe 'when draft exists for same station, same song, within time window' do
      let(:broadcasted_at) { Time.current }

      before do
        create(:air_play, :draft, radio_station:, song:,
                                  broadcasted_at: broadcasted_at - 5.minutes)
      end

      it 'finds the draft' do
        expect(AirPlay.find_draft_for_confirmation(radio_station, song, broadcasted_at)).to be_present
      end
    end

    describe 'when draft exists but outside time window' do
      let(:broadcasted_at) { Time.current }

      before do
        create(:air_play, :draft, radio_station:, song:,
                                  broadcasted_at: broadcasted_at - 15.minutes)
      end

      it 'does not find the draft' do
        expect(AirPlay.find_draft_for_confirmation(radio_station, song, broadcasted_at)).to be_nil
      end
    end

    describe 'when confirmed air play exists (not draft)' do
      let(:broadcasted_at) { Time.current }

      before do
        create(:air_play, :confirmed, radio_station:, song:,
                                      broadcasted_at: broadcasted_at - 5.minutes)
      end

      it 'does not return confirmed air plays' do
        expect(AirPlay.find_draft_for_confirmation(radio_station, song, broadcasted_at)).to be_nil
      end
    end
  end

  describe '#matching_spotify_track? edge cases' do
    let(:importer) { described_class.new(radio_station:) }

    context 'when track is nil' do
      before do
        importer.instance_variable_set(:@song, song)
        importer.instance_variable_set(:@track, nil)
      end

      it 'returns false' do
        expect(importer.send(:matching_spotify_track?)).to be false
      end
    end

    context 'when track does not respond to spotify_song_url' do
      let(:non_spotify_track) do
        Struct.new(:id).new('itunes123')
      end

      before do
        importer.instance_variable_set(:@song, song)
        importer.instance_variable_set(:@track, non_spotify_track)
      end

      it 'returns false' do
        expect(importer.send(:matching_spotify_track?)).to be false
      end
    end

    context 'when song has no Spotify ID' do
      let(:song_without_spotify) { create(:song, title: 'No Spotify', id_on_spotify: nil) }
      let(:track) do
        instance_double(Spotify::TrackFinder::Result,
                        id: 'spotify123',
                        spotify_song_url: 'https://open.spotify.com/track/spotify123')
      end

      before do
        importer.instance_variable_set(:@song, song_without_spotify)
        importer.instance_variable_set(:@track, track)
      end

      it 'returns false' do
        expect(importer.send(:matching_spotify_track?)).to be false
      end
    end

    context 'when track id is blank' do
      let(:track) do
        instance_double(Spotify::TrackFinder::Result,
                        id: nil,
                        spotify_song_url: 'https://open.spotify.com/track/')
      end

      before do
        importer.instance_variable_set(:@song, song)
        importer.instance_variable_set(:@track, track)
      end

      it 'returns false' do
        expect(importer.send(:matching_spotify_track?)).to be false
      end
    end
  end
end
