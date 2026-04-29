# Airplays

Airplays is a Ruby on Rails 8.1 API-only application that monitors Dutch radio stations, recognizes and scrapes currently playing songs, enriches them with data from Spotify, YouTube, Last.fm, Deezer, and iTunes, and generates charts. Uses Sidekiq for background job processing.

## Features

- **Audio Recognition**: Dual recognition via SongRec (Shazam-based) and AcoustID (Chromaprint) fingerprinting
- **Track Scraping**: Polymorphic processors for radio station APIs (Talpa, QMusic, SLAM!, KINK, NPO, GNR, MediaHuis, Arrow) and video OCR (Yoursafe)
- **Song Enrichment**: Spotify, Deezer, iTunes, Last.fm, YouTube, MusicBrainz, and Wikipedia integration
- **Chart Generation**: Daily charts with popularity boost scoring from Spotify and Last.fm data
- **Persistent Streams**: Long-lived ffmpeg connections for ad-free stream capture
- **JWT Authentication**: Two-tier auth with frontend client tokens and admin Devise-JWT
- **Rate Limiting**: Per-endpoint rate limits using Rails 8 built-in `rate_limit`
- **Widget Endpoints**: Public embeddable data endpoints for songs, artists, and radio stations
- **RESTful API**: JSON API under `/api/v1/` with Swagger documentation

## Technologies Used

- **Backend**: Ruby 4.0.2, Rails 8.1
- **Database**: PostgreSQL
- **Background Jobs**: Sidekiq with Redis
- **Caching**: Redis
- **Audio Recognition**: SongRec (Shazam), Chromaprint + AcoustID
- **Audio/Video Processing**: FFmpeg
- **OCR**: Tesseract (via rtesseract gem)
- **Song Enrichment**: Spotify, Deezer, iTunes, Last.fm, YouTube, MusicBrainz APIs
- **Testing**: RSpec, VCR, WebMock
- **Code Quality**: RuboCop, Brakeman, bundler-audit
- **CI/CD**: GitHub Actions (test, rubocop, security, swagger drift, build, deploy)
- **API Documentation**: rswag (Swagger/OpenAPI)
- **Monitoring**: Sentry
- **Containerization**: Docker with multi-stage builds

## Setup Instructions

### Prerequisites

- Ruby 4.0.2 (version specified in `.ruby-version`)
- PostgreSQL
- Redis
- SongRec ([installation guide](https://github.com/marin-m/SongRec))
- FFmpeg ([installation guide](https://ffmpeg.org/download.html))
- Chromaprint (`fpcalc` CLI)
- Tesseract OCR

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/samuelvaneck/airplays.git
   cd airplays
   ```
2. Install Ruby gems:
   ```bash
   bundle install
   ```
3. Create, migrate and seed the database:
   ```bash
   rails db:create db:schema:load db:seed
   ```
4. Start the Rails server:
   ```bash
   rails server
   ```
5. Start the Sidekiq worker:
   ```bash
   bundle exec sidekiq
   ```
6. Start persistent streams (optional):
   ```bash
   bundle exec rake persistent_streams:start
   ```

Or run everything in Docker:
```bash
docker-compose up
```

## Common Commands

```bash
# Testing
bundle exec rspec                           # Run all tests
bundle exec rspec spec/path/to/file_spec.rb # Run single test file

# Code Quality
bundle exec rubocop                         # Lint
bundle exec brakeman -i config/brakeman.ignore  # Security scan (suppresses triaged findings)
bundle exec bundle-audit check --update     # Check Gemfile for known CVEs

# API Documentation
bundle exec rake rswag:specs:swaggerize     # Regenerate Swagger docs
```

## CI/CD

GitHub Actions pipelines (`.github/workflows/`):

- **`ci.yml`** — runs on every push to `main` and every PR. Jobs:
  - `actionlint` — lints workflow YAML
  - `test` — RSpec with JUnit reporting (failures surface inline on PRs)
  - `rubocop` — style/lint
  - `security` — Brakeman (gated by `config/brakeman.ignore`) + bundler-audit (CVE check)
  - `swagger` — regenerates `swagger/v1/swagger.yaml` and fails if it's out of date
  - `build-and-push` — builds and pushes the Docker image to GHCR. Only runs on `main` after every other job passes.
- **`rubocop-analysis.yml`** — uploads RuboCop findings as SARIF for GitHub code scanning.
- **`deploy.yml`** — manual `workflow_dispatch` deploy. Verifies the image tag exists in GHCR via `docker manifest inspect` before SSHing to production.
- **`dependabot.yml`** — keeps action versions up to date weekly.

## API Documentation

Swagger docs are available at `/api-docs` when the server is running.
