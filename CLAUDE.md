# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Airplays is a Ruby on Rails 8.1 API-only application that monitors Dutch radio stations, recognizes/scrapes songs, enriches them with Spotify/YouTube data, and generates charts. Uses Sidekiq for background job processing.

## Where the deeper docs live

These nested `CLAUDE.md` files load automatically when Claude Code is working in those directories:

- [`app/services/CLAUDE.md`](app/services/CLAUDE.md) — service-oriented design, data flow, Spotify/LLM track finding, chart scoring, hit potential, audio recognition, persistent streams
- [`app/jobs/CLAUDE.md`](app/jobs/CLAUDE.md) — Sidekiq queues, scheduled and on-demand jobs, memory monitor
- [`app/models/CLAUDE.md`](app/models/CLAUDE.md) — key models, model concerns, slug generation
- [`app/controllers/CLAUDE.md`](app/controllers/CLAUDE.md) — API structure, search/suggestions, auth & rate limiting, charts endpoint, swagger, security
- [`spec/CLAUDE.md`](spec/CLAUDE.md) — VCR conventions, multiple-expectations rule, swaggerize requirement

## Common Commands

```bash
# Testing
bundle exec rspec                           # Run all tests
bundle exec rspec spec/path/to/file_spec.rb # Run single test file
bundle exec rspec spec/path/to/file_spec.rb:42 # Run specific test line

# Code Quality
bundle exec rubocop                         # Lint (auto-fixes enabled)
bundle exec brakeman -i config/brakeman.ignore  # Security scan (suppresses triaged findings)
bundle exec bundle-audit check --update     # Check Gemfile.lock for known CVEs

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

# Data Repair
bundle exec rake data_repair:verify_songs[limit]              # Detect Spotify mismatches
bundle exec rake data_repair:fix_songs[limit]                 # Auto-fix mismatched songs
bundle exec rake data_repair:merge_duplicate_isrcs             # Merge songs with same ISRC
bundle exec rake data_repair:find_fuzzy_duplicates             # Find fuzzy song duplicates
bundle exec rake data_repair:confirm_recognizer_drafts         # Confirm draft airplays for recognizer-only stations
bundle exec rake data_repair:find_mismatched_airplays[limit]   # Dry run: detect airplays linked to wrong songs
bundle exec rake data_repair:fix_mismatched_airplays[limit]    # Fix airplays linked to wrong songs
bundle exec rake data_repair:find_contaminated_isrcs[limit]    # Dry run: find songs with cross-contaminated ISRCs
bundle exec rake data_repair:fix_contaminated_isrcs[limit]     # Fix songs with cross-contaminated ISRCs
bundle exec rake data_repair:rollback_import_log[log_id]       # Dry run: preview rollback of a single SongImportLog
bundle exec rake data_repair:rollback_import_log[log_id,apply] # Apply: destroy airplay, destroy song if orphaned, mark log failed
bundle exec rake data_repair:find_stuck_pending_logs[limit]    # Dry run: detect SongImportLogs stuck in pending status
bundle exec rake data_repair:fix_stuck_pending_logs[limit]     # Recover stuck pending logs by linking/creating airplays
bundle exec rake optimization:vacuum                           # PostgreSQL VACUUM FULL ANALYZE

# Hit Potential
bundle exec rake hit_potential:backfill                        # Backfill hit_potential_score for songs with music profiles

# Lyrics Sentiment
bundle exec rake lyrics:backfill                               # Enqueue lyrics sentiment enrichment for recently-played songs (requires LYRICS_ENRICHMENT_ENABLED=true)

# Enrichment
bundle exec rake enrichment:backfill_artist_aka_names          # Fetch alternative artist names from MusicBrainz
bundle exec rake enrichment:backfill_artist_country            # Fetch artist country (ISO code + name) from MusicBrainz

# Slugs
bundle exec rake slug:backfill_songs                           # Backfill slugs for songs without one
bundle exec rake slug:backfill_artists                         # Backfill slugs for artists without one
bundle exec rake slug:backfill_all                             # Backfill slugs for both songs and artists
bundle exec rake slug:repair_empty                             # Regenerate slugs built from empty parameterize output (non-Latin titles)

# Memory Diagnostics
bundle exec rake memory:stats                                  # Show RSS, GC stats, top object classes
bundle exec rake memory:heap_dump                              # Dump ObjectSpace heap to JSON for analysis
bundle exec rake memory:profile_job[JobClass,N]                # Compare object counts before/after N job runs
```

## Code Style

- Max line length: 150 characters
- RSpec context prefixes: `when`, `with`, `without`, `if`, `unless`, `for`
- Class structure order enforced: constants → includes → hooks → associations → validations → scopes → class methods → instance methods
- Uses JSONAPI serializers in `app/serializers/`

## Docker

### Production Image (Multi-Stage Build)

The `Dockerfile` uses a two-stage build with `ruby:4.0.2-slim-bookworm`:

1. **Builder stage** — installs build deps (`build-essential`, `libpq-dev`, `libyaml-dev`, `libicu-dev`, `zlib1g-dev`, `pkg-config`), SongRec from PPA, and runs `bundle install`
2. **Runtime stage** — installs only runtime deps (`libpq5`, `libyaml-0-2`, `libicu72`, `ffmpeg`, `libchromaprint-tools`, `tesseract-ocr` + language packs, `libjemalloc2`, `songrec`), copies built app and gems from builder

### Memory Optimization

- **jemalloc** enabled via `LD_PRELOAD="libjemalloc.so.2"` — reduces Ruby memory fragmentation by 20-40%. Uses bare library name (not full path) to work on both x86_64 and aarch64.
- **`MALLOC_ARENA_MAX=2`** — limits glibc arena bloat in multi-threaded processes
- **Sidekiq concurrency** — tuned per queue (10 / 3 / 5 for `realtime` / `compute` / `enrichment`); each thread holds a DB connection so total threads must fit Postgres `max_connections`
- **docker-compose memory limits** — 2G for web, 768M for `sidekiq_realtime`, 1G for `sidekiq_compute`, 768M for `sidekiq_enrichment`, 1G for `persistent_streams`

### SongRec PPA Installation

SongRec is installed from the Launchpad PPA using `gpg --dearmor` (not `add-apt-repository`, which doesn't work on slim images):

```dockerfile
wget -qO- '...' | gpg --dearmor -o /etc/apt/trusted.gpg.d/songrec.gpg
echo 'deb http://ppa.launchpad.net/marin-m/songrec/ubuntu jammy main' > /etc/apt/sources.list.d/songrec.list
```

### Important: LD_PRELOAD and Bundle Install

`LD_PRELOAD` must be set **after** `bundle install` — setting it before causes gem native extension compilation to fail with "cannot be preloaded" errors. In multi-stage builds, only set it in the runtime stage.

## CI/CD

GitHub Actions workflows live in `.github/workflows/`.

### `ci.yml`

Runs on every PR and on `push` to `main`. Concurrency is keyed on `workflow+ref` and cancels in-progress runs on PR branches but never on `main` (so post-merge build/deploy isn't aborted by a follow-up commit).

Jobs:
- **`actionlint`** — lints workflow YAML via `reviewdog/action-actionlint`. Catches expression errors and deprecated inputs before they break a real run.
- **`test`** — RSpec with `RspecJunitFormatter`; `mikepenz/action-junit-report` surfaces failing examples inline on the PR diff. Coverage and `log/` are uploaded as artifacts on success/failure respectively.
- **`rubocop`** — style/lint gate.
- **`security`** — Brakeman + bundler-audit. Brakeman is gated by `config/brakeman.ignore` (each suppression has a justification note); new findings fail the job. bundler-audit checks `Gemfile.lock` against the ruby-advisory-db.
- **`swagger`** — regenerates `swagger/v1/swagger.yaml` via `rake rswag:specs:swaggerize` and fails if the working tree is dirty. Enforces the rule that swagger be committed alongside spec changes.
- **`build-and-push`** — Docker buildx build, push to `ghcr.io/samuelvaneck/airplays`. `needs: [actionlint, test, rubocop, security, swagger]` and gated to `push` on `main`, so the image only ships when every other job is green.

### `rubocop-analysis.yml`

Uploads RuboCop findings as SARIF for GitHub code scanning. Runs alongside `ci.yml` but doesn't gate the build (`code-scanning-rubocop` formatter is informational).

### `deploy.yml`

Manual `workflow_dispatch` only. Logs in to GHCR and runs `docker manifest inspect ghcr.io/samuelvaneck/airplays:$TAG` before SSHing — a typo'd or non-existent tag fails fast at the manifest step instead of redeploying the previous release.

### `dependabot.yml`

Weekly grouped updates for the `github-actions` ecosystem. Keeps action versions current without per-action PR noise.

### Adding/changing CI

- Workflow YAML changes will trigger the `actionlint` job — run `actionlint .github/workflows/*.yml` locally if available, or rely on the CI gate.
- New action versions: prefer Node 24 majors (e.g. `actions/checkout@v6`, `docker/build-push-action@v7`). Older Node 20 majors emit a deprecation warning on the runner and will stop working in late 2026.

## External Dependencies

- **SongRec** - Shazam-based audio fingerprinting (must be installed locally)
- **Chromaprint** - AcoustID fingerprinting via `fpcalc` CLI (must be installed locally)
- **Tesseract** - OCR engine for video frame text extraction (must be installed locally, used by `rtesseract` gem)
- **FFmpeg** - Audio/video processing (must be installed locally)
- **PostgreSQL** - Primary database
- **Redis** - Caching (db #1) and Sidekiq (db #2)
- **yt-dlp** - YouTube audio downloading for AcoustID fingerprint population
- **Sentry** - Error tracking and performance monitoring (env var: `SENTRY_DSN`)
- **OpenAI** - GPT-4.1-mini for natural language search query translation (env var: `OPENAI_API_KEY`)
- **Tidal Open API** - Catalog enrichment for songs (env vars: `TIDAL_CLIENT_ID`, `TIDAL_CLIENT_SECRET`). Auth at `auth.tidal.com/v1/oauth2/token`, data at `openapi.tidal.com/v2/...`. API reference: https://tidal-music.github.io/tidal-api-reference/. Paths are case-sensitive (e.g. `/v2/searchResults`, not `/v2/searchresults`).
