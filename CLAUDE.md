# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
Radio Playlists is a Ruby on Rails application that tracks and processes songs played by various radio stations. It uses web scraping, API integration, and audio stream recognition to collect playlist data, with Spotify API enrichment and background job processing via Sidekiq.

## Development Commands

### Setup & Installation
```bash
# Install dependencies
bundle install

# Database setup
rails db:create
rails db:schema:load
rails db:seed

# Start development servers (Rails + Sidekiq)
bin/dev
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/path/to/spec_file.rb

# Run tests with coverage
COVERAGE=true bundle exec rspec
```

### Code Quality
```bash
# Run RuboCop for linting
bundle exec rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -A

# Security analysis
bundle exec brakeman
```

### Background Jobs
```bash
# Start Sidekiq worker
bundle exec sidekiq

# Access Sidekiq web UI (when server running)
# Visit: http://localhost:3000/sidekiq
```

### Database Tasks
```bash
# Run migrations
rails db:migrate

# Deduplicate air plays
rails air_plays:deduplicate
```

## Architecture Overview

### Service Layer Pattern
The application uses a service object pattern with key services located in `app/services/`:

- **Track Scrapers** (`app/services/track_scraper/`): API processors for different radio stations (Talpa, Qmusic, SLAM!, KINK, NPO, MediaHuis)
- **Audio Stream Processing** (`app/services/audio_stream/`): Handles M3U8 and MP3 stream processing
- **Song Recognition** (`app/services/song_recognizer.rb`): Integrates with SongRec for audio fingerprinting
- **Spotify Integration** (`app/services/spotify/`): Track and artist finding, audio features extraction
- **Song Importers** (`app/services/song_importer/`): Manages song data import from scrapers and recognizers

### Background Job Processing
Scheduled jobs via Sidekiq (see `config/sidekiq.yml`):
- `ImportSongsAllRadioStationsJob`: Runs every minute
- `RadioStationTracksScraperJob`: Runs every 3 minutes
- `YoutubeApiImportJob`: Runs every 15 minutes
- `ChartCreationJob`: Daily at 00:10
- `SendStatusEmail`: Daily at 02:00 (disabled by default)

### API Structure
RESTful API under `api/v1` namespace:
- Air plays (playlists)
- Artists with graph data and chart positions
- Songs with graph data and chart positions
- Radio stations with status and classifiers

### External Dependencies
- **SongRec**: Audio fingerprinting tool (must be installed separately)
- **FFMpeg**: Audio processing (must be installed separately)
- **PostgreSQL**: Primary database
- **Redis**: Sidekiq queue backend

### Data Flow
1. Radio stations are scraped via API processors or audio stream recognition
2. Songs are matched/created using fuzzy matching (Jaro-Winkler distance)
3. Spotify API enriches song metadata and audio features
4. Air plays are recorded with deduplication logic
5. Charts are generated daily from air play data

## Testing Approach
- RSpec for unit and integration tests
- Factory Bot for test data generation
- VCR for recording/replaying external API calls
- WebMock for mocking HTTP requests
- Database Cleaner for test database management

## Docker Support
Application can run in Docker containers using `docker-compose up`. See `docker-compose.yml` for service configuration.