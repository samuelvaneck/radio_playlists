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

# Database
rails db:create db:schema:load db:seed      # Initial setup
rails db:migrate                            # Run migrations

# Server
rails server                                # Start Rails (port 3000)
bundle exec sidekiq                         # Start background jobs
docker-compose up                           # Full stack with Docker
```

## Architecture

### Service-Oriented Design

The app uses service objects extensively in `app/services/`:
- `SongImporter` - Orchestrates song import workflow (matcher, recognizer, scraper sub-services)
- `TrackScraper/` - Polymorphic processors for radio station APIs (Talpa, QMusic, SLAM!, KINK, NPO, GNR, MediaHuis)
- `TrackExtractor/` - Extracts artist/song info and finds Spotify tracks
- `Spotify/` and `Youtube/` - External API integrations
- `Lastfm/` and `Wikipedia/` - Artist bio/info enrichment
- `AudioStream/` - M3U8 and MP3 stream handling
- `SongRecognizer` - Audio fingerprinting via SongRec

### Background Jobs

Sidekiq jobs in `app/jobs/` run on schedules defined in `config/sidekiq.yml`:
- `ImportSongsAllRadioStationsJob` - Every minute, imports songs from all stations
- `RadioStationTracksScraperJob` - Every 3 minutes, scrapes station playlists
- `ChartCreationJob` - Daily at 00:10, generates charts
- `YoutubeApiImportJob` - Every 15 minutes

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
- `RadioStationClassifier` - Spotify audio features by time-of-day

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

### Preventing Secrets in VCR Cassettes

**IMPORTANT:** VCR cassettes can inadvertently contain sensitive data. Always review cassettes before committing.

Common secrets to watch for:
- `Set-Cookie` headers (session tokens, auth cookies like `_abck`, `bm_sz`)
- `Authorization` headers (Bearer tokens, API keys)
- Response body tokens (`access_token`, `track_token`, `refresh_token`)
- API keys in query parameters or headers

The VCR configuration in `spec/support/vcr.rb` filters Spotify tokens automatically. When adding new API integrations:

1. **Add filters** for any sensitive data in `spec/support/vcr.rb`:
```ruby
config.filter_sensitive_data('<FILTERED>') { ENV['API_KEY'] }

# Filter Set-Cookie headers
config.before_record do |interaction|
  interaction.response.headers.delete('Set-Cookie')
end
```

2. **Review cassettes** before committing - check for tokens, cookies, and session data
3. **Remove unnecessary headers** from recorded responses that aren't needed for tests

For tests that need real HTTP requests (no mocking), use `:real_http`:
```ruby
context 'with live API call', :real_http do
  it 'fetches real data' do
    # WebMock and VCR are disabled for this test
  end
end
```

## API Structure

RESTful JSON API under `/api/v1/`:
- `songs`, `artists`, `air_plays`, `radio_stations`
- Admin endpoints with JWT authentication (Devise)
- Swagger docs available at `/api-docs` (rswag)

## External Dependencies

- **SongRec** - Audio fingerprinting (must be installed locally)
- **FFmpeg** - Audio processing (must be installed locally)
- **PostgreSQL** - Primary database
- **Redis** - Caching (db #1) and Sidekiq (db #2)
