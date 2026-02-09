# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Radio Playlists is a Ruby on Rails 8 API application that monitors Dutch radio stations, recognizes/scrapes songs, enriches them with Spotify/YouTube data, and generates charts. Uses Sidekiq for background job processing.

## Common Commands

```bash
# Testing
bundle exec rspec                           # Run all tests
bundle exec rspec spec/path/to/file_spec.rb # Run single test file
bundle exec rspec spec/path/to/file_spec.rb:42 # Run specific test line

# Code Quality
bundle exec rubocop                         # Lint (auto-fixes enabled)
bundle exec brakeman                        # Security scan

# API Documentation
bundle exec rake rswag:specs:swaggerize     # Regenerate swagger/v1/swagger.yaml

# Database
rails db:create db:schema:load db:seed      # Initial setup
rails db:migrate                            # Run migrations

# Server
rails server                                # Start Rails (port 3000)
bundle exec sidekiq                         # Start background jobs
docker-compose up                           # Full stack with Docker

# Persistent Streams
bundle exec rake persistent_streams:start   # Start stream manager (blocking)
bundle exec rake persistent_streams:status  # Show per-station status
```

## Architecture

### Service-Oriented Design

The app uses service objects extensively in `app/services/`:
- `SongImporter` - Orchestrates song import workflow (matcher, recognizer, scraper sub-services)
- `SongRecognizer` - Shazam-based audio fingerprinting via SongRec
- `AcoustidRecognizer` - Chromaprint + AcoustID API fingerprinting
- `TrackScraper/` - Polymorphic processors for radio station APIs (Talpa, QMusic, SLAM!, KINK, NPO, GNR, MediaHuis)
- `TrackExtractor/` - Extracts artist/song info and finds Spotify tracks
- `Spotify/` and `Youtube/` - External API integrations
- `Lastfm/` and `Wikipedia/` - Artist bio/info enrichment
- `AudioStream/` - M3U8, MP3, and PersistentSegment stream handling
- `PersistentStream/` - Long-lived ffmpeg processes for ad-free stream capture (see below)

### Background Jobs

Sidekiq jobs in `app/jobs/` run on schedules defined in `config/sidekiq.yml`:
- `ImportSongsAllRadioStationsJob` - Every minute, imports songs from all stations
- `RadioStationTracksScraperJob` - Every 3 minutes, scrapes station playlists
- `ChartCreationJob` - Daily at 00:10, generates charts
- `YoutubeApiImportJob` - Every 15 minutes

### Persistent Stream Manager

Replaces Icecast relay dependency for ad-free stream capture. Radio stations connecting directly trigger ~30s pre-roll ads; persistent streams avoid this by maintaining long-lived ffmpeg connections.

- `RadioStation#direct_stream_url` — direct station stream URL (when set, persistent streams are preferred)
- `RadioStation#stream_url` — Icecast relay URL (used as fallback)
- `PersistentStream::Process` — manages one ffmpeg process per station, writing rolling 10-second segments to `tmp/audio/persistent/{station}/`
- `PersistentStream::SegmentReader` — reads latest completed segment from ffmpeg's `segments.csv`, with 30s staleness threshold
- `PersistentStream::Manager` — orchestrates all processes, health-checks every 30s, auto-restarts dead processes
- `AudioStream::PersistentSegment` — AudioStream subclass used by SongImporter when persistent segments are available
- `SongImporter#build_audio_stream` — prefers persistent segments, falls back to Icecast stream

Run via `Procfile.dev` (`streams` entry) or `docker-compose.yml` (`persistent_streams` service).

### Data Flow

```
Radio Stream → Audio Recognition/Scraping → Artist/Song Extraction
    → Spotify API Lookup → Database Storage → Chart Generation
```

### Key Models

- `Song` / `Artist` - Core entities with Spotify/YouTube IDs
- `AirPlay` - Song play events (unique per station/song/time)
- `RadioStation` - Station metadata with last 12 airplay IDs (JSONB)
- `ChartPosition` - Polymorphic rankings (can be Song or Artist)
- `MusicProfile` - Spotify audio features per song (used for in-place classifier calculations)

### Model Concerns

Located in `app/models/concerns/`:
- `ChartConcern` - Chart ranking logic
- `GraphConcern` - Data visualization queries
- `DateConcern` - Date filtering utilities
- `TimeAnalyticsConcern` - Temporal analysis
- `LifecycleConcern` - Model lifecycle callbacks

## Code Style

- Max line length: 150 characters
- RSpec context prefixes: `when`, `with`, `without`, `if`, `unless`, `for`
- Class structure order enforced: constants → includes → hooks → associations → validations → scopes → class methods → instance methods
- Uses JSONAPI serializers in `app/serializers/`

## Testing

### VCR for External API Calls

Use VCR to record and replay HTTP interactions for tests involving external APIs. This ensures tests are deterministic and don't depend on external services.

```ruby
# Add :use_vcr metadata to contexts that make external HTTP requests
context 'when API returns valid data', :use_vcr do
  it 'returns the expected data' do
    result = MyService.new.call
    expect(result).to be_present
  end
end
```

VCR cassettes are stored in `spec/fixtures/vcr_cassettes/` and are automatically named based on the test description. Prefer VCR over mocking Faraday/HTTP responses directly when testing service objects that call external APIs.

For tests that need real HTTP requests (no mocking), use `:real_http`:
```ruby
context 'with live API call', :real_http do
  it 'fetches real data' do
    # WebMock and VCR are disabled for this test
  end
end
```

### Multiple Expectations

The `RSpec/MultipleExpectations` cop is enabled with `Max: 1`. When you need multiple expectations in a single example, use `:aggregate_failures` to group them:

```ruby
it 'returns the correct response', :aggregate_failures do
  expect(response).to have_http_status(:ok)
  expect(json['data']).to be_an(Array)
  expect(json['data'].first['id']).to eq(record.id)
end
```

This tells RuboCop that the expectations are intentionally grouped, and RSpec will run all expectations even if earlier ones fail (providing better error messages).

## API Structure

RESTful JSON API under `/api/v1/`:
- `songs`, `artists`, `air_plays`, `radio_stations`
- Admin endpoints with JWT authentication (Devise)
- Swagger docs available at `/api-docs` (rswag)

### Swagger Documentation

API specs in `spec/requests/api/v1/` generate the Swagger documentation. After modifying API specs:

```bash
bundle exec rake rswag:specs:swaggerize     # Regenerates swagger/v1/swagger.yaml
```

Schema definitions are configured in `spec/swagger_helper.rb`. The generated `swagger/v1/swagger.yaml` should be committed to version control.

## External Dependencies

- **SongRec** - Shazam-based audio fingerprinting (must be installed locally)
- **Chromaprint** - AcoustID fingerprinting via `fpcalc` CLI (must be installed locally)
- **FFmpeg** - Audio processing (must be installed locally)
- **PostgreSQL** - Primary database
- **Redis** - Caching (db #1) and Sidekiq (db #2)

## Audio Recognition

### Current Implementation: Dual Recognition (SongRec + AcoustID)

Both recognizers run on each import for comparison. Results are stored in `SongImportLog`.

**Services:**
- `SongRecognizer` - Shazam-based recognition via SongRec CLI (primary, high accuracy)
- `AcoustidRecognizer` - Chromaprint + AcoustID API (queries MusicBrainz database)

**Comparison fields in SongImportLog:**
- `recognized_*` - SongRec results (artist, title, isrc, spotify_url, raw_response)
- `acoustid_*` - AcoustID results (artist, title, recording_id, score, raw_response)

**Limitation:** AcoustID only recognizes songs in MusicBrainz database (limited Dutch radio coverage).

### Audio Duration Requirements

Current recording duration is **5 seconds** for direct Icecast capture (configured in `app/services/audio_stream/mp3.rb` and `m3u8.rb`) and **10 seconds** for persistent stream segments (configured in `app/services/persistent_stream/process.rb`).

**SongRec vs AcoustID duration needs:**

| Duration | SongRec (Shazam) | AcoustID |
|----------|------------------|----------|
| 5 sec    | Works well       | Too short |
| 30 sec   | Works well       | Marginal |
| 60+ sec  | Works well       | Reliable |

**AcoustID requirements:**
- Very short tracks (15-30 seconds) produce too small a sample size and are prone to incorrect matches
- Chromaprint analyzes approximately 2 minutes of audio for optimal fingerprinting
- Recordings differing by more than 7 seconds in length will always get different AcoustIDs
- The current 5-second samples are insufficient for reliable AcoustID matching

**Sources:**
- https://wiki.musicbrainz.org/Guides/AcoustID
- https://groups.google.com/g/acoustid/c/C3EHIkZVpZI

### Planned: Populate AcoustID Database

To improve AcoustID coverage for Dutch radio songs, submit fingerprints from known songs.

**Strategy: Use YouTube audio tracks**
1. When SongRec identifies a song, get the YouTube video (already stored in `Song#id_on_youtube`)
2. Download audio from YouTube using `yt-dlp`
3. Generate fingerprint with `fpcalc`
4. Look up MusicBrainz recording ID (via artist + title search)
5. Submit fingerprint + MusicBrainz ID to AcoustID

**AcoustID Submit API:**
```
POST https://api.acoustid.org/v2/submit

Parameters:
- client: Application API key (ACOUSTID_API_KEY)
- user: Personal user API key (get from acoustid.org after signing in)
- duration.0: Audio duration in seconds
- fingerprint.0: Chromaprint fingerprint
- mbid.0: MusicBrainz recording ID (links fingerprint to metadata)
- track.0, artist.0: Optional metadata
```

**Implementation notes:**
- Submissions are processed asynchronously
- Rate limit: max 3 requests/second
- Need to register for a user API key at https://acoustid.org
- Consider batch processing existing songs with YouTube IDs
- MusicBrainz API: https://musicbrainz.org/doc/MusicBrainz_API
