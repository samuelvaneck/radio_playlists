# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Airplays is a Ruby on Rails 8.1 API-only application that monitors Dutch radio stations, recognizes/scrapes songs, enriches them with Spotify/YouTube data, and generates charts. Uses Sidekiq for background job processing.

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
bundle exec rake optimization:vacuum                           # PostgreSQL VACUUM FULL ANALYZE

# Hit Potential
bundle exec rake hit_potential:backfill                        # Backfill hit_potential_score for songs with music profiles

# Enrichment
bundle exec rake enrichment:backfill_artist_aka_names          # Fetch alternative artist names from MusicBrainz

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

## Architecture

### Service-Oriented Design

The app uses service objects extensively in `app/services/`:
- `SongImporter` - Orchestrates song import workflow, split into concerns: `AudioRecognition`, `TrackFinding`, `AirPlayCreation`, `ArtistUpdating` (in `app/services/song_importer/concerns/`)
- `SongRecognizer` - Shazam-based audio fingerprinting via SongRec
- `AcoustidRecognizer` - Chromaprint + AcoustID API fingerprinting
- `TrackScraper/` - Polymorphic processors for radio station APIs (Talpa, QMusic, SLAM!, KINK, NPO, GNR, MediaHuis, Arrow, MyTuner, Simone) and video OCR (Yoursafe). Uses `faraday-retry` gem for transient error retries
- `TrackExtractor/` - Extracts artist/song info and finds tracks via `SpotifyTrackFinder`, `DeezerTrackFinder`, `ItunesTrackFinder`. Both `SpotifyTrackFinder` and `SongExtractor` use fuzzy search fallbacks with JaroWinkler title validation (>= 70%) to prevent matching different songs by the same artist.
- `Spotify/` - External API integration with two track-finding paths: search-based (`best_match`) and ID-based (`fetch_spotify_track`). Both compute JaroWinkler match scores for `valid_match?` validation (artist >= 80, title >= 70)
- `Youtube/` - YouTube API integration
- `Lastfm/` and `Wikipedia/` - Artist bio/info enrichment (Last.fm listeners/playcount/tags, Wikipedia nationality via Wikidata)
- `Deezer/` and `Itunes/` - Additional enrichment sources (duration_ms, release_date backfill)
- `ClientTokenGenerator` - Generates short-lived JWT tokens (10-minute expiry) for frontend client authentication
- `MusicBrainz/` - ISRCs enrichment for songs and `ArtistAliasFetcher` for populating `Artist#aka_names` (legal names, stylization variants like P!nk/Pink, former names via `artist rename` relations)
- `AudioStream/` - M3U8, MP3, and PersistentSegment stream handling
- `PersistentStream/` - Long-lived ffmpeg processes for ad-free stream capture (see below)
- `CombinedArtistSplitter` - Splits combined artist names (e.g., "Artist feat. Artist2") into individual Artist records
- `DuplicateArtistMerger` - Finds and merges duplicate artists via Spotify ID or fuzzy name matching (Jaro-Winkler, threshold: 92)
- `DuplicateSongMerger` - Finds and merges duplicate songs via Spotify ID or fuzzy title matching (Jaro-Winkler, threshold: 92)
- `MismatchedAirplayRepair` - Detects and fixes airplays linked to wrong songs via two detectors: (1) title mismatch — import log title vs linked song title (Jaro-Winkler < 70%); (2) spotify_track_id mismatch — the log's Spotify ID points to a different canonical song than the one linked. Reassigns airplays to the canonical song (found by Spotify track ID, exact match, or newly created).
- `SongImportLogRollback` - Rolls back a single `SongImportLog`: destroys the linked airplay, destroys the linked song if no other airplays reference it, marks the log `failed` with a rollback reason. Guards against orphaning charts (skips song deletion if chart positions exist) and preserves songs played on other stations.
- `HitPotentialCalculator` - Predicts song hit potential (0-100) using multi-signal scoring: audio features (50%), artist popularity (20%), engagement metrics (15%), release recency (15%)
- `SoundProfileGenerator` - Generates per-station sound profiles with audio feature averages, top genres/tags, release decade distribution, and bilingual descriptions (EN/NL). Uses song-count-weighted percentiles and peak decade detection (≥15% threshold) for accurate era descriptions instead of naive min/max year ranges
- `NaturalLanguageSearch` - Translates free-text queries (e.g., "upbeat Dutch songs on Radio 538 last week") into structured filters via `Llm::QueryTranslator`, then applies faceted search. Supports mood-based filtering using Spotify audio feature ranges, result limiting ("top 3 songs", "most popular song" → `.limit()`), and lyrics-based song identification
- `Llm::Base` - OpenAI GPT-4.1-mini integration with 1-hour response caching, circuit breaker, and exponential backoff
- `Llm::QueryTranslator` - System prompt that instructs GPT to output JSON filter objects. Supports text search, facets (genre, country, radio_station), temporal filters, mood mappings (upbeat, chill, danceable, etc. → audio feature ranges), sorting, result limit (clamped 1-50), and lyrics-based song identification (GPT identifies artist+title from quoted lyrics; falls back to text_search if unrecognized). Handles both English and Dutch queries
- `Llm::TrackNameCleaner` - Cleans scraped artist/title for Spotify search (fixes titleize artifacts like "Dj"→"DJ", missing diacritics, radio station tags, chart prefixes). Only called when Spotify returned no results or names match known dirty patterns — skipped when Spotify already found results (search terms were adequate)
- `Llm::AlternativeSearchQueries` - Generates 2-3 alternative Spotify search queries when original search returned zero results. Includes artist name simplification (e.g., "Opwekking Band met Marcel Zimmer" → "Opwekking") and track/catalog number handling (e.g., "785 Fundament" → "Fundament")
- `Llm::BorderlineMatchValidator` - Validates borderline Spotify matches (title similarity 60-69%, artist already passes) by asking GPT if scraped and matched songs are the same
- `Llm::ProgramDetector` - Detects radio programs/shows (e.g., SLAM! "Housuh In De Pauzuh") vs actual songs. Only called when artist name resembles station name AND no Spotify match was found. Response cached 1 hour

### Background Jobs

Sidekiq jobs in `app/jobs/` run on schedules defined in `config/sidekiq.yml`:
- `ImportSongsAllRadioStationsJob` - Every minute, imports songs from all stations
- `RadioStationTracksScraperJob` - Every 3 minutes, scrapes station playlists
- `ChartCreationJob` - Daily at 00:10, generates charts
- `ChartSongEnrichmentJob` - Daily at 00:30, re-enriches charted songs with latest Last.fm/Spotify data for popularity boost
- `YoutubeApiImportJob` - Every 15 minutes
- `CleanupDraftAirPlaysJob` - Every hour, cleans draft airplays older than 4 hours and orphaned SongImportLogs
- `SongImportMonitorJob` - Every hour, monitors import failure rates and alerts
- `SongImportLogCleanupJob` - Daily at 2am, exports and deletes old import logs
- `DatabaseVacuumJob` - Daily at 3am, runs VACUUM ANALYZE on key tables to prevent bloat
- `AvgSongGapCalculationJob` - Daily at 5am, calculates per-station average song gaps
- `ArtistEnrichmentBatchJob` - Weekly Sunday 3am, batch enqueues artist enrichment
- `LastfmEnrichmentBatchJob` - Weekly Sunday 4am, batch enqueues Last.fm enrichment for songs/artists

On-demand enrichment jobs (triggered by import flow, not scheduled):
- `SongExternalIdsEnrichmentJob` - Enriches songs with Deezer, iTunes, and MusicBrainz IDs after import
- `MusicProfileJob` - Creates Spotify audio feature profiles for songs, then calculates `hit_potential_score` via `HitPotentialCalculator`
- `AcoustidPopulationJob` - Downloads YouTube audio, generates fingerprints, submits to AcoustID

**Important:** `ImportSongJob` uses `sidekiq-unique-jobs` with `lock: :until_executed` and `lock_ttl: 90`, plus a 60-second `Timeout.timeout` wrapper around `SongImporter#import`. The wall-clock timeout caps each job at one minute (covering edge-case hangs not handled by inner subprocess/HTTP timeouts), and `lock_ttl` is set higher than the timeout so the unique lock spans the full execution — otherwise the per-minute scheduler would enqueue duplicates while a slow job is still running, and they would pile up across worker threads.

### Sidekiq Memory Monitor

`Sidekiq::MemoryMonitorMiddleware` (`lib/sidekiq/memory_monitor_middleware.rb`) tracks per-job RSS growth to detect memory leaks. Registered in `config/initializers/sidekiq.rb`.

**What it does:**
1. Measures RSS before/after every job — logs warnings for jobs that grow memory by >= threshold
2. Every N jobs, logs periodic stats: cumulative RSS growth since boot, GC stats, top object classes, and per-job growth rankings
3. Tracks cumulative growth per job class over the Sidekiq process lifetime

**Environment variables:**
- `SIDEKIQ_MEMORY_MONITOR` — enable/disable (default: `'true'`, set `'false'` to disable)
- `MEMORY_GROWTH_THRESHOLD_MB` — RSS growth per job to trigger a warning log (default: `5` MB)
- `MEMORY_STATS_INTERVAL` — periodic stats frequency in jobs (default: `100`)

**Diagnostic rake tasks** (`lib/tasks/memory.rake`):
- `rake memory:stats` — snapshot of RSS, GC stats, top 30 object classes by count, top 20 by memory
- `rake memory:heap_dump` — dumps ObjectSpace to `tmp/heap_dump_*.json` for analysis with `heapy` or `jq`
- `rake memory:profile_job[JobClass,N]` — runs a job N times and compares object counts before/after to find leaks (e.g. `rake memory:profile_job[ImportSongJob,10]`)

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
Radio Stream → Audio Recognition/Scraping → @played_song (artist, title, isrc)
    → skip_import? checks:
        1. blank/illegal title? → skip
        2. recently_imported? (same scraped data in last hour) → skip
        3. radio_program? (artist ≈ station name, no Spotify match, LLM confirms) → skip
    ├→ SpotifyTrackFinder  (artist, title, isrc from @played_song)
    ├→ DeezerTrackFinder   (artist, title, isrc from @played_song)
    └→ ItunesTrackFinder   (artist, title from @played_song)
    → Song matching (prefers Spotify, falls back to iTunes, then Deezer)
    → AirPlay creation → Chart Generation
```

**Import skip checks** (`SongImporter#skip_import?`):
- `recently_imported?` — cheap DB `exists?` query (before track finding). Blocks repeated import attempts when the scraper returns the same artist/title/broadcasted_at within 1 hour. Only for scraper imports
- `radio_program?` — detects radio shows/segments (e.g., SLAM! "Housuh In De Pauzuh") via heuristic + LLM. Only fires when: scraper import, artist name resembles station name (`artist_resembles_station?`), AND `track` is nil (no Spotify match). Uses `Llm::ProgramDetector` (cached 1 hour)

**Important:** All three enrichment services (Spotify, Deezer, iTunes) independently receive the recognized/scraped data from `@played_song`. Deezer and iTunes do **not** use Spotify's response — they each search using the original artist/title/ISRC from the recognizer or scraper. `SongImporter#track` prefers Spotify, falls back to iTunes, then Deezer. If all fail, `SongExtractor#find_or_create_by_title` creates the song from scraped data alone (no external service validation).

**LLM-enhanced track finding** (`TrackFinding` concern, gated by `LLM_IMPORT_ENABLED` env var):
1. **Alternative search queries** — when Spotify returns zero results, `Llm::AlternativeSearchQueries` generates 2-3 variant queries (simplify artist names, fix diacritics, handle track numbers, remove noise)
2. **Borderline match validation** — when Spotify match has title similarity 60-69% but artist passes (>= 80%), `Llm::BorderlineMatchValidator` asks GPT if they're the same song
3. **Track name cleanup** — last resort fallback. Only fires when Spotify returned no results OR scraped names contain fixable patterns (titleize artifacts, noise suffixes, chart prefixes, station tags). Cleans names via `Llm::TrackNameCleaner` and retries Spotify
4. **Second-round alternative queries** — when track name cleanup fixes the title but the direct search still fails, runs `AlternativeSearchQueries` again with the cleaned names to simplify the artist (e.g., "Opwekking Band met Marcel Zimmer" → "Opwekking")

**Spotify Track Finding** has two paths in `Spotify::TrackFinder::Result`:
1. **Search-based** (`best_match`) — searches Spotify API by artist+title, filters by album type, picks best match with JaroWinkler scores
2. **ID-based** (`fetch_spotify_track`) — used when `SpotifyTrackFinder#existing_song_spotify_id` finds a known Spotify ID, or when a scraper provides a `spotify_url`. Fetches track by ID via `FindById`, then validates with match scores

Both paths compute `artist_distance`/`title_distance` and require `valid_match?` (artist >= 80, title >= 70) before the track is accepted.

**Post-import enrichment:** `SongExternalIdsEnrichmentJob` runs after each import to enrich songs with Deezer, iTunes, and MusicBrainz data. Note: there is no Spotify enrichment in this job — Spotify IDs are only set during the import flow.

### Chart Scoring & Popularity Boost

Chart positions are sorted by weekly airplay count. Tiebreakers use a popularity boost multiplier (1.0–~1.30) calculated from:
- Spotify popularity: up to +15% contribution
- Last.fm listeners: up to +10% (log-normalized)
- Last.fm playcount: up to +5% (log-normalized)

Formula: `(weekly_airplay * 100) + (popularity_boost * 50)`. Artists default to boost of 1.0.

### Hit Potential Score

`HitPotentialCalculator` predicts how likely a song is to be a hit (0-100), combining four signal categories based on academic research:

| Signal | Weight | Data Source | Research Basis |
|--------|--------|-------------|----------------|
| Audio features | 50% | `MusicProfile` (danceability, energy, loudness, etc.) | Rusconi 2024, ~80-89% accuracy |
| Artist popularity | 20% | `Artist#spotify_popularity`, `spotify_followers_count`, `lastfm_listeners` | Interiano 2018: +15% accuracy |
| Engagement metrics | 15% | `Song#popularity`, `lastfm_listeners`, `lastfm_playcount` | Mountzouris 2025 |
| Release recency | 15% | `Song#release_date` (exponential decay, 5-year half-life) | SpotiPred 2022 |

Audio features use Gaussian scoring against optimal ranges for popular songs (e.g., danceability center=0.64, loudness center=-6.0 dB), with per-feature weights from Random Forest feature importance. Engagement and follower counts are log-normalized.

The score is calculated automatically by `MusicProfileJob` after creating a music profile, and stored as `Song#hit_potential_score`. Use `rake hit_potential:backfill` to compute scores for existing songs.

### Key Models

- `Song` - Core entity with Spotify/YouTube IDs, enrichment fields (`album_name`, `popularity`, `explicit`, `duration_ms`, `release_date`, `isrcs` array, `lastfm_listeners`, `lastfm_playcount`, `lastfm_tags`, `hit_potential_score`), `slug` for SEO-friendly URLs
- `Artist` - Core entity with enrichment fields (`genres` array, `country_of_origin` array, `spotify_popularity`, `spotify_followers_count`, `lastfm_listeners`, `lastfm_playcount`, `lastfm_tags`, `aka_names` array, `id_on_musicbrainz`), `slug` for SEO-friendly URLs
- `AirPlay` - Song play events (unique per station/song/time, `broadcasted_at` presence validated)
- `RadioStation` - Station metadata with last 12 airplay IDs (JSONB), `is_currently_playing` flag on last_played_songs endpoint, `slug` for SEO-friendly URLs
- `ChartPosition` - Polymorphic rankings (can be Song or Artist), with popularity boost tiebreaker
- `MusicProfile` - Spotify audio features per song: 7 core features + extended features (`key`, `mode`, `loudness`, `time_signature`)

### Model Concerns

Located in `app/models/concerns/`:
- `ChartConcern` - Chart ranking logic
- `GraphConcern` - Data visualization queries
- `DateConcern` - Date filtering utilities
- `TimeAnalyticsConcern` - Temporal analysis
- `LifecycleConcern` - Model lifecycle callbacks
- `PeriodParser` - Parses granular time ranges (`1_day`, `7_days`, `4_weeks`, `1_year`, etc.) into durations and aggregation patterns for charts and analytics
- `SongSearchConcern` - Faceted search and suggestions for songs. Filters: artist (trigram + ILIKE on Artist), title, album, year range. Suggestions use 3-tier relevance ordering: exact match → prefix match → trigram similarity, then popularity tiebreaker. Shared helper `SongSearchConcern.relevance_order` generates the ORDER BY SQL
- `ArtistSearchConcern` - Faceted search and suggestions for artists. Filters: name (trigram + ILIKE), genre (array containment `@>`), country (array containment). Same relevance ordering for suggestions via `SongSearchConcern.relevance_order`

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
- `songs`, `artists`, `air_plays`, `radio_stations`, `charts`
- `GET /api/v1/artists/:id/similar_artists` — Returns artists with overlapping genres/Last.fm tags, sorted by similarity score then Spotify popularity
- `GET /api/v1/radio_stations/release_date_graph` — Groups airplays by station and song release year for time-series visualization

### Search & Suggestions

**Faceted search** — filter and sort with structured parameters:
- `GET /api/v1/songs/search` — params: `q`, `artist`, `title`, `album`, `year_from`, `year_to`, `sort_by` (`most_played`/`newest`/`popularity`), `limit` (max 20), `page` (24 per page)
- `GET /api/v1/artists/search` — params: `q`, `name`, `genre`, `country`, `sort_by` (`most_played`/default popularity), `limit` (max 20), `page`

**Natural language search** — LLM translates free-text queries to structured filters:
- `GET /api/v1/songs/natural_language_search` — params: `q` (required), `page`. Response includes `filters` (decoded) and `query` alongside results. Supports limit queries ("top 3 songs on Sky Radio last month") and lyrics search ("I heard a song with the lyrics hello from the other side")
- `GET /api/v1/artists/natural_language_search` — params: `q` (required), `page`. Same limit support as songs

**Suggestions** — autocomplete for specific fields, relevance-ordered:
- `GET /api/v1/songs/search_suggestions` — params: `field` (`artist`/`title`/`album`/`year`), `q`, `limit` (max 10)
- `GET /api/v1/artists/search_suggestions` — params: `field` (`name`/`genre`/`country`), `q`, `limit` (max 10)

### Slug-Based Lookup

Songs, artists, and radio stations support lookup by slug in addition to numeric ID for SEO-friendly URLs (e.g. `/songs/blinding-lights-the-weeknd`, `/artists/the-weeknd`, `/radio-stations/sky-radio`).

**Pattern:** Controllers use `params[:id].to_i.to_s == params[:id]` to detect numeric IDs vs slugs, then route to `find` or `find_by!(slug:)` accordingly. Slugs are auto-generated on create via `before_create` callbacks and updated on title/name changes via `after_commit`. Duplicate slugs get numeric suffixes (`slug-2`, `slug-3`).

**Slug format:**
- Songs: `"#{title} #{primary_artist_name}".parameterize` (e.g. `blinding-lights-the-weeknd`)
- Artists: `name.parameterize` (e.g. `the-weeknd`)
- Radio stations: `name.parameterize` (e.g. `sky-radio`)

**Important:** `Song.most_played` and `Artist.most_played` use explicit `.select()` lists. When adding new serialized attributes, they must also be added to these select clauses to avoid `ActiveModel::MissingAttributeError`.
- Sound profile endpoint (public, no auth required):
  - `GET /api/v1/radio_stations/:id/sound_profile` — audio feature averages, top genres/tags, release decade distribution, bilingual descriptions (`description_en`/`description_nl`), era analysis with weighted percentiles (`release_year_range.era_description_en`/`era_description_nl`, `peak_decades`, `median_year`)
- Widget endpoints (public, no auth required):
  - `GET /api/v1/songs/:id/widget` — total plays, station count, release date, duration
  - `GET /api/v1/artists/:id/widget` — total plays, song count, station count, country of origin
  - `GET /api/v1/radio_stations/:id/widget` — top song/artist (last week), songs played (last 24h), new songs (last 7 days)
- Admin endpoints with JWT authentication (Devise)
- Swagger docs available at `/api-docs` (rswag)

### Authentication & Rate Limiting

Two-tier JWT authentication:

1. **Frontend client JWT** (`FRONTEND_JWT_SECRET`) — lightweight tokens for public API access
   - Generated via `POST /api/v1/client_tokens` (requires `FRONTEND_CLIENT_ID` + `FRONTEND_CLIENT_SECRET`)
   - `ClientTokenGenerator` creates HS256 tokens with 10-minute expiry
   - Enforced by `before_action :authenticate_client!` in `ApiController`
   - Skipped if `FRONTEND_JWT_SECRET` env var is not set
2. **Admin JWT** (`DEVISE_JWT_SECRET_KEY`) — Devise-JWT with JTI revocation strategy, 60-minute expiry

**Exempt from client authentication:** widget endpoints and `stream_proxy`

**Rate limits** (Rails 8 built-in `rate_limit`):
- General API: 300 req/min per IP
- Client token creation: 10 req/min per IP
- Radio station classifiers: 30 req/min per IP
- Stream proxy: 5 req/min per IP

### Charts Endpoint

`GET /api/v1/charts` — Returns paginated chart positions with nested song/artist data.

**Query parameters:**
- `type` — `songs` (default) or `artists`
- `date` — specific chart date (`YYYY-MM-DD`), defaults to latest available
- `period` — granular time range (`1_day`, `7_days`, `4_weeks`, `1_year`, etc.), parsed by `PeriodParser`
- `page` — pagination (24 items per page)

Each entry includes `previous_position` (from the prior day's chart) for movement indicators. Returns `null` for new entries not on the previous chart. Uses `ChartPositionSerializer` with nested `SongSerializer`/`ArtistSerializer`.

### Swagger Documentation

API specs in `spec/requests/api/v1/` generate the Swagger documentation. After modifying API specs:

```bash
bundle exec rake rswag:specs:swaggerize     # Regenerates swagger/v1/swagger.yaml
```

Schema definitions are configured in `spec/swagger_helper.rb`. The generated `swagger/v1/swagger.yaml` should be committed to version control.

**Important:** Always run `bundle exec rake rswag:specs:swaggerize` and commit the updated `swagger/v1/swagger.yaml` after adding or modifying request specs in `spec/requests/api/v1/`. The CI `swagger` job regenerates the file and fails if the working tree is dirty, so a missed swaggerize run will block the PR.

### Security

- **SSRF protection** - Stream proxy validates HTTPS-only URLs, blocks private IPs (loopback, private ranges, link-local), limits redirect chains to 5 levels
- **Command injection prevention** - All external CLI calls (`fpcalc`, `songrec`, `ffmpeg`, `tesseract`) use array-based `Open3.capture3` instead of shell strings
- **Stream URL privacy** - `direct_stream_url` hidden from public API serializer
- **CORS** - Whitelisted origins via `CORS_ALLOWED_ORIGINS` env var, Netlify preview pattern, and production domain
- **Sidekiq Web UI** - Protected with basic auth. Sidekiq 8 requires session middleware (`ActionDispatch::Cookies` + `Session::CookieStore`) added in `config/application.rb` for API-only apps

## Docker

### Production Image (Multi-Stage Build)

The `Dockerfile` uses a two-stage build with `ruby:4.0.2-slim-bookworm`:

1. **Builder stage** — installs build deps (`build-essential`, `libpq-dev`, `libyaml-dev`, `libicu-dev`, `zlib1g-dev`, `pkg-config`), SongRec from PPA, and runs `bundle install`
2. **Runtime stage** — installs only runtime deps (`libpq5`, `libyaml-0-2`, `libicu72`, `ffmpeg`, `libchromaprint-tools`, `tesseract-ocr` + language packs, `libjemalloc2`, `songrec`), copies built app and gems from builder

### Memory Optimization

- **jemalloc** enabled via `LD_PRELOAD="libjemalloc.so.2"` — reduces Ruby memory fragmentation by 20-40%. Uses bare library name (not full path) to work on both x86_64 and aarch64.
- **`MALLOC_ARENA_MAX=2`** — limits glibc arena bloat in multi-threaded processes
- **Sidekiq concurrency: 10** — balances throughput vs memory (each thread holds a DB connection)
- **docker-compose memory limits** — 512M for web/streams, 1G for sidekiq

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

## Audio Recognition

### Current Implementation: Dual Recognition (SongRec + AcoustID)

Both recognizers run on each import for comparison. Results are stored in `SongImportLog`.

**Services:**
- `SongRecognizer` - Shazam-based recognition via SongRec CLI (primary, high accuracy)
- `AcoustidRecognizer` - Chromaprint + AcoustID API (queries MusicBrainz database)

**Comparison fields in SongImportLog:**
- `recognized_*` - SongRec results (artist, title, isrcs, spotify_url, raw_response)
- `acoustid_*` - AcoustID results (artist, title, recording_id, score, raw_response)
- `llm_action` - Which LLM feature was used (`track_name_cleanup`, `alternative_search_queries`, `borderline_match_validation`). Single field — only the last LLM action per import is stored
- `llm_raw_response` - Request/response pair from the LLM call

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

### Video OCR Recognition (Yoursafe Radio)

Yoursafe Radio streams via Amazon IVS HLS with a video overlay displaying "JE LUISTERT NAAR" + album art + "Artist - Title". Since the stream has no API and the timed_id3 metadata only contains infrastructure data (segment numbers, timestamps, loudness), the `YoursafeVideoProcessor` uses OCR to extract track info.

**Flow:**
1. `ffmpeg` captures a single video frame from the HLS stream
2. `RTesseract` (Tesseract OCR wrapper) reads text from the frame
3. Parser finds the last line containing ` - ` separator (skipping header lines like "JE LUISTERT NAAR")
4. Splits into artist name and title

**Dependencies:** `tesseract-ocr` + language packs (`eng`, `nld`, `deu`, `fra`, `spa`, `ita`, `por`, `rus`, `tur`) system packages, `rtesseract` gem. The full language set is configured in `YoursafeVideoProcessor::OCR_LANGUAGES` so Tesseract can read Cyrillic and other non-Latin scripts that appear on the overlay (e.g., Russian tracks).

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
