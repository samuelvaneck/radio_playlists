# frozen_string_literal: true

describe SongImportLogger do
  let(:radio_station) { create(:radio_station) }
  let(:logger) { described_class.new(radio_station:) }

  describe '#start_log' do
    it 'creates a new song import log' do
      expect { logger.start_log }.to change(SongImportLog, :count).by(1)
    end

    it 'sets the radio station' do
      logger.start_log
      expect(logger.log.radio_station).to eq(radio_station)
    end

    it 'sets status to pending' do
      logger.start_log
      expect(logger.log.status).to eq('pending')
    end

    it 'sets broadcasted_at' do
      logger.start_log
      expect(logger.log.broadcasted_at).to be_within(1.second).of(Time.zone.now)
    end

    it 'accepts custom broadcasted_at' do
      custom_time = 1.hour.ago
      logger.start_log(broadcasted_at: custom_time)
      expect(logger.log.broadcasted_at).to be_within(1.second).of(custom_time)
    end
  end

  describe '#log_recognition' do
    let(:recognizer) do
      instance_double(
        SongRecognizer,
        artist_name: 'Test Artist',
        title: 'Test Song',
        isrc_code: 'USTEST1234567',
        spotify_url: 'spotify:track:123abc',
        result: { track: { title: 'Test Song' } }
      )
    end

    before { logger.start_log }

    it 'updates the log with recognition data' do
      logger.log_recognition(recognizer)

      expect(logger.log.recognized_artist).to eq('Test Artist')
      expect(logger.log.recognized_title).to eq('Test Song')
      expect(logger.log.recognized_isrc).to eq('USTEST1234567')
      expect(logger.log.recognized_spotify_url).to eq('spotify:track:123abc')
      expect(logger.log.import_source).to eq('recognition')
    end

    it 'stores the raw response' do
      logger.log_recognition(recognizer)
      expect(logger.log.recognized_raw_response).to eq({ 'track' => { 'title' => 'Test Song' } })
    end

    it 'does nothing if log is nil' do
      new_logger = described_class.new(radio_station:)
      expect { new_logger.log_recognition(recognizer) }.not_to raise_error
    end
  end

  describe '#log_scraping' do
    let(:scraper) do
      instance_double(
        TrackScraper,
        artist_name: 'Scraped Artist',
        title: 'Scraped Song',
        isrc_code: nil,
        spotify_url: 'https://open.spotify.com/track/456'
      )
    end
    let(:raw_response) { { tracks: [{ title: 'Scraped Song' }] } }

    before { logger.start_log }

    it 'updates the log with scraping data' do
      logger.log_scraping(scraper, raw_response:)

      expect(logger.log.scraped_artist).to eq('Scraped Artist')
      expect(logger.log.scraped_title).to eq('Scraped Song')
      expect(logger.log.import_source).to eq('scraping')
    end

    it 'stores the raw response' do
      logger.log_scraping(scraper, raw_response:)
      expect(logger.log.scraped_raw_response).to eq({ 'tracks' => [{ 'title' => 'Scraped Song' }] })
    end
  end

  describe '#log_spotify' do
    let(:spotify_track) do
      instance_double(
        Spotify::TrackFinder::Result,
        artists: [{ 'name' => 'Spotify Artist' }],
        title: 'Spotify Song',
        id: 'spotify123',
        isrc: 'USSPOTIFY1234',
        track: { 'id' => 'spotify123', 'name' => 'Spotify Song' }
      )
    end

    before { logger.start_log }

    it 'updates the log with Spotify data' do
      logger.log_spotify(spotify_track)

      expect(logger.log.spotify_artist).to eq('Spotify Artist')
      expect(logger.log.spotify_title).to eq('Spotify Song')
      expect(logger.log.spotify_track_id).to eq('spotify123')
      expect(logger.log.spotify_isrc).to eq('USSPOTIFY1234')
    end

    it 'stores the raw track data' do
      logger.log_spotify(spotify_track)
      expect(logger.log.spotify_raw_response).to eq({ 'id' => 'spotify123', 'name' => 'Spotify Song' })
    end
  end

  describe '#complete_log' do
    let(:song) { create(:song) }
    let(:air_play) { create(:air_play, song:) }

    before { logger.start_log }

    it 'updates status to success' do
      logger.complete_log(song:, air_play:)
      expect(logger.log.status).to eq('success')
    end

    it 'links the song and air_play' do
      logger.complete_log(song:, air_play:)
      expect(logger.log.song).to eq(song)
      expect(logger.log.air_play).to eq(air_play)
    end
  end

  describe '#fail_log' do
    before { logger.start_log }

    it 'updates status to failed' do
      logger.fail_log(reason: 'API error')
      expect(logger.log.status).to eq('failed')
    end

    it 'stores the failure reason' do
      logger.fail_log(reason: 'API error')
      expect(logger.log.failure_reason).to eq('API error')
    end
  end

  describe '#skip_log' do
    before { logger.start_log }

    it 'updates status to skipped' do
      logger.skip_log(reason: 'No artist found')
      expect(logger.log.status).to eq('skipped')
    end

    it 'stores the skip reason' do
      logger.skip_log(reason: 'No artist found')
      expect(logger.log.failure_reason).to eq('No artist found')
    end
  end
end
