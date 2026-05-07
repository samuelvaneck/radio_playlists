# Services

Guidance for `app/services/`. The root `CLAUDE.md` has project-wide context and commands.

## Service-Oriented Design

The app uses service objects extensively in `app/services/`:
- `SongImporter` - Orchestrates song import workflow, split into concerns: `AudioRecognition`, `TrackFinding`, `AirPlayCreation`, `ArtistUpdating` (in `app/services/song_importer/concerns/`)
- `SongRecognizer` - Shazam-based audio fingerprinting via SongRec
- `AcoustidRecognizer` - Chromaprint + AcoustID API fingerprinting
- `TrackScraper/` - Polymorphic processors for radio station APIs (Talpa, QMusic, SLAM!, KINK, NPO, GNR, MediaHuis, Arrow, MyTuner, Simone) and video OCR (Yoursafe). Uses `faraday-retry` gem for transient error retries
- `TrackExtractor/` - Extracts artist/song info and finds tracks via `SpotifyTrackFinder`, `DeezerTrackFinder`, `ItunesTrackFinder`. Both `SpotifyTrackFinder` and `SongExtractor` use fuzzy search fallbacks with JaroWinkler title validation (>= 70%) to prevent matching different songs by the same artist.
- `Spotify/` - External API integration with two track-finding paths: search-based (`best_match`) and ID-based (`fetch_spotify_track`). Both compute JaroWinkler match scores for `valid_match?` validation (artist >= 80, title >= 70)
- `Youtube/` - YouTube API integration
- `Lastfm/` and `Wikipedia/` - Artist bio/info enrichment (Last.fm listeners/playcount/tags, Wikipedia bio/summary). Country of origin comes from `MusicBrainz::ArtistCountryFinder` (ISO 3166-1 alpha-2 stored as `country_code`, full name derived via the `countries` gem and stored as `country_of_origin`).
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
- `StuckPendingLogRecovery` - Recovers `SongImportLog` rows stuck in `pending` status (jobs killed mid-flight before reaching a terminal status). For each stuck log with a `spotify_track_id`: resolves the canonical Song (by Spotify ID, then exact artist+title, then create), reuses an existing AirPlay at `(radio_station, song, broadcasted_at)` if one was created before the interruption, otherwise creates one, and marks the log `success`. Skips logs without `spotify_track_id` and logs younger than `min_age` (default 10 minutes).
- `HitPotentialCalculator` - Predicts song hit potential (0-100) using multi-signal scoring: audio features (45%), artist popularity (20%), engagement metrics (15%), release recency (10%), lyrics sentiment (10%). Songs without analyzed lyrics receive a neutral 0.5 lyrics score
- `Lyrics/` - LRCLIB lyrics fetching (`LrclibFinder`). Free, public-domain-leaning corpus, no auth. Stores only sentiment + metadata + LRCLIB URL on the `Lyric` model — full lyrics text is refetched on demand to avoid licensing concerns.
- `Llm::LyricsSentimentAnalyzer` - Analyzes lyrics with GPT-4.1-mini and returns `{sentiment: -1..1, themes: [...], language, confidence}`. Multilingual (Dutch + English + others)
- `LyricsSentimentTrendCalculator` - Time-bucketed average lyrics sentiment for a station's airplays. Granularity follows the period: hour for days, day for weeks/months, month for years, year for "all"
- `SoundProfileGenerator` - Generates per-station sound profiles with audio feature averages, top genres/tags, release decade distribution, and bilingual descriptions (EN/NL). Uses song-count-weighted percentiles and peak decade detection (≥15% threshold) for accurate era descriptions instead of naive min/max year ranges
- `NaturalLanguageSearch` - Translates free-text queries (e.g., "upbeat Dutch songs on Radio 538 last week") into structured filters via `Llm::QueryTranslator`, then applies faceted search. Supports mood-based filtering using Spotify audio feature ranges, result limiting ("top 3 songs", "most popular song" → `.limit()`), and lyrics-based song identification
- `Llm::Base` - OpenAI GPT-4.1-mini integration with 1-hour response caching, circuit breaker, and exponential backoff
- `Llm::QueryTranslator` - System prompt that instructs GPT to output JSON filter objects. Supports text search, facets (genre, country, radio_station), temporal filters, mood mappings (upbeat, chill, danceable, etc. → audio feature ranges), sorting, result limit (clamped 1-50), and lyrics-based song identification (GPT identifies artist+title from quoted lyrics; falls back to text_search if unrecognized). Handles both English and Dutch queries
- `Llm::TrackNameCleaner` - Cleans scraped artist/title for Spotify search (fixes titleize artifacts like "Dj"→"DJ", missing diacritics, radio station tags, chart prefixes). Only called when Spotify returned no results or names match known dirty patterns — skipped when Spotify already found results (search terms were adequate)
- `Llm::AlternativeSearchQueries` - Generates 2-3 alternative Spotify search queries when original search returned zero results. Includes artist name simplification (e.g., "Opwekking Band met Marcel Zimmer" → "Opwekking") and track/catalog number handling (e.g., "785 Fundament" → "Fundament")
- `Llm::BorderlineMatchValidator` - Validates borderline Spotify matches (title similarity 60-69%, artist already passes) by asking GPT if scraped and matched songs are the same
- `Llm::ProgramDetector` - Detects radio programs/shows (e.g., SLAM! "Housuh In De Pauzuh") vs actual songs. Only called when artist name resembles station name AND no Spotify match was found. Response cached 1 hour

## Persistent Stream Manager

Replaces Icecast relay dependency for ad-free stream capture. Radio stations connecting directly trigger ~30s pre-roll ads; persistent streams avoid this by maintaining long-lived ffmpeg connections.

- `RadioStation#direct_stream_url` — direct station stream URL (when set, persistent streams are preferred)
- `RadioStation#stream_url` — Icecast relay URL (used as fallback)
- `PersistentStream::Process` — manages one ffmpeg process per station, writing rolling 10-second segments to `tmp/audio/persistent/{station}/`
- `PersistentStream::SegmentReader` — reads latest completed segment from ffmpeg's `segments.csv`, with 30s staleness threshold
- `PersistentStream::Manager` — orchestrates all processes, health-checks every 30s, auto-restarts dead processes
- `AudioStream::PersistentSegment` — AudioStream subclass used by SongImporter when persistent segments are available
- `SongImporter#build_audio_stream` — prefers persistent segments, falls back to Icecast stream

Run via `Procfile.dev` (`streams` entry) or `docker-compose.yml` (`persistent_streams` service).

## Data Flow

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

## Chart Scoring & Popularity Boost

Chart positions are sorted by weekly airplay count. Tiebreakers use a popularity boost multiplier (1.0–~1.30) calculated from:
- Spotify popularity: up to +15% contribution
- Last.fm listeners: up to +10% (log-normalized)
- Last.fm playcount: up to +5% (log-normalized)

Formula: `(weekly_airplay * 100) + (popularity_boost * 50)`. Artists default to boost of 1.0.

## Hit Potential Score

`HitPotentialCalculator` predicts how likely a song is to be a hit (0-100), combining five signal categories based on academic research:

| Signal | Weight | Data Source | Research Basis |
|--------|--------|-------------|----------------|
| Audio features | 45% | `MusicProfile` (danceability, energy, loudness, etc.) | Rusconi 2024, ~80-89% accuracy |
| Artist popularity | 20% | `Artist#spotify_popularity`, `spotify_followers_count`, `lastfm_listeners` | Interiano 2018: +15% accuracy |
| Engagement metrics | 15% | `Song#popularity`, `lastfm_listeners`, `lastfm_playcount` | Mountzouris 2025 |
| Release recency | 10% | `Song#release_date` (exponential decay, 5-year half-life) | SpotiPred 2022 |
| Lyrics sentiment | 10% | `Lyric#sentiment` (linear -1..1 → 0..1; neutral 0.5 when missing) | Lyrics for Success, ACL 2024 |

Audio features use Gaussian scoring against optimal ranges for popular songs (e.g., danceability center=0.64, loudness center=-6.0 dB), with per-feature weights from Random Forest feature importance. Engagement and follower counts are log-normalized.

The score is calculated automatically by `MusicProfileJob` after creating a music profile, and stored as `Song#hit_potential_score`. Use `rake hit_potential:backfill` to compute scores for existing songs.

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
