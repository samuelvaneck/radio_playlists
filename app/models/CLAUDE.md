# Models

Guidance for `app/models/`. The root `CLAUDE.md` has project-wide context.

## Key Models

- `Song` - Core entity with Spotify/YouTube IDs, enrichment fields (`album_name`, `popularity`, `explicit`, `duration_ms`, `release_date`, `isrcs` array, `lastfm_listeners`, `lastfm_playcount`, `lastfm_tags`, `hit_potential_score`), `slug` for SEO-friendly URLs
- `Artist` - Core entity with enrichment fields (`genres` array, `country_of_origin` array, `country_code` (ISO 3166-1 alpha-2), `spotify_popularity`, `spotify_followers_count`, `lastfm_listeners`, `lastfm_playcount`, `lastfm_tags`, `aka_names` array, `id_on_musicbrainz`), `slug` for SEO-friendly URLs
- `AirPlay` - Song play events (unique per station/song/time, `broadcasted_at` presence validated)
- `RadioStation` - Station metadata with last 12 airplay IDs (JSONB), `is_currently_playing` flag on last_played_songs endpoint, `slug` for SEO-friendly URLs
- `ChartPosition` - Polymorphic rankings (can be Song or Artist), with popularity boost tiebreaker
- `MusicProfile` - Spotify audio features per song: 7 core features + extended features (`key`, `mode`, `loudness`, `time_signature`)

## Model Concerns

Located in `app/models/concerns/`:
- `ChartConcern` - Chart ranking logic
- `GraphConcern` - Data visualization queries
- `DateConcern` - Date filtering utilities
- `TimeAnalyticsConcern` - Temporal analysis
- `LifecycleConcern` - Model lifecycle callbacks
- `PeriodParser` - Parses granular time ranges (`1_day`, `7_days`, `4_weeks`, `1_year`, etc.) into durations and aggregation patterns for charts and analytics
- `SongSearchConcern` - Faceted search and suggestions for songs. Filters: artist (trigram + ILIKE on Artist), title, album, year range. Suggestions use 3-tier relevance ordering: exact match → prefix match → trigram similarity, then popularity tiebreaker. Shared helper `SongSearchConcern.relevance_order` generates the ORDER BY SQL
- `ArtistSearchConcern` - Faceted search and suggestions for artists. Filters: name (trigram + ILIKE), genre (array containment `@>`), country (array containment). Same relevance ordering for suggestions via `SongSearchConcern.relevance_order`

## Slug-Based Lookup

Songs, artists, and radio stations support lookup by slug in addition to numeric ID for SEO-friendly URLs (e.g. `/songs/blinding-lights-the-weeknd`, `/artists/the-weeknd`, `/radio-stations/sky-radio`).

Slugs are auto-generated on create via `before_create` callbacks and updated on title/name changes via `after_commit`. Duplicate slugs get numeric suffixes (`slug-2`, `slug-3`).

**Slug format:**
- Songs: `"#{title} #{primary_artist_name}".parameterize` (e.g. `blinding-lights-the-weeknd`)
- Artists: `name.parameterize` (e.g. `the-weeknd`)
- Radio stations: `name.parameterize` (e.g. `sky-radio`)

**Important:** `Song.most_played` and `Artist.most_played` use explicit `.select()` lists. When adding new serialized attributes, they must also be added to these select clauses to avoid `ActiveModel::MissingAttributeError`.
