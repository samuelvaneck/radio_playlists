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
- `TrackScraper/` - 8 polymorphic processors for different radio station APIs (Talpa, QMusic, SLAM!, KINK, NPO, GNR, MediaHuis)
- `Spotify/` and `Youtube/` - External API integrations
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

## Code Style

- Max line length: 150 characters
- RSpec context prefixes: `when`, `with`, `without`, `if`, `unless`, `for`
- Class structure order enforced: constants → includes → hooks → associations → validations → scopes → class methods → instance methods
- Uses JSONAPI serializers in `app/serializers/`

## API Structure

RESTful JSON API under `/api/v1/`:
- `songs`, `artists`, `air_plays`, `radio_stations`
- Admin endpoints with JWT authentication (Devise)

## External Dependencies

- **SongRec** - Audio fingerprinting (must be installed locally)
- **FFmpeg** - Audio processing (must be installed locally)
- **PostgreSQL** - Primary database
- **Redis** - Caching (db #1) and Sidekiq (db #2)
