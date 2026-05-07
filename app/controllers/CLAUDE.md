# Controllers / API

Guidance for `app/controllers/`. The root `CLAUDE.md` has project-wide context.

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

**Pattern:** Controllers use `params[:id].to_i.to_s == params[:id]` to detect numeric IDs vs slugs, then route to `find` or `find_by!(slug:)` accordingly. See `app/models/CLAUDE.md` for slug format and generation details.

### Public (no auth) endpoints

- Sound profile endpoint:
  - `GET /api/v1/radio_stations/:id/sound_profile` — audio feature averages, top genres/tags, release decade distribution, bilingual descriptions (`description_en`/`description_nl`), era analysis with weighted percentiles (`release_year_range.era_description_en`/`era_description_nl`, `peak_decades`, `median_year`)
- Sentiment trend endpoint:
  - `GET /api/v1/radio_stations/:id/sentiment_trend?period=4_weeks` — time-bucketed average lyrics sentiment per station. Granularity follows the period (hour for days, day for weeks/months, month for years, year for "all"). Songs without analyzed lyrics are excluded from the average
- Widget endpoints:
  - `GET /api/v1/songs/:id/widget` — total plays, station count, release date, duration
  - `GET /api/v1/artists/:id/widget` — total plays, song count, station count, country of origin
  - `GET /api/v1/radio_stations/:id/widget` — top song/artist (last week), songs played (last 24h), new songs (last 7 days)

Admin endpoints use JWT authentication (Devise). Swagger docs available at `/api-docs` (rswag).

## Authentication & Rate Limiting

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

## Charts Endpoint

`GET /api/v1/charts` — Returns paginated chart positions with nested song/artist data.

**Query parameters:**
- `type` — `songs` (default) or `artists`
- `date` — specific chart date (`YYYY-MM-DD`), defaults to latest available
- `period` — granular time range (`1_day`, `7_days`, `4_weeks`, `1_year`, etc.), parsed by `PeriodParser`
- `page` — pagination (24 items per page)

Each entry includes `previous_position` (from the prior day's chart) for movement indicators. Returns `null` for new entries not on the previous chart. Uses `ChartPositionSerializer` with nested `SongSerializer`/`ArtistSerializer`.

## Swagger Documentation

API specs in `spec/requests/api/v1/` generate the Swagger documentation. After modifying API specs:

```bash
bundle exec rake rswag:specs:swaggerize     # Regenerates swagger/v1/swagger.yaml
```

Schema definitions are configured in `spec/swagger_helper.rb`. The generated `swagger/v1/swagger.yaml` should be committed to version control.

**Important:** Always run `bundle exec rake rswag:specs:swaggerize` and commit the updated `swagger/v1/swagger.yaml` after adding or modifying request specs in `spec/requests/api/v1/`. The CI `swagger` job regenerates the file and fails if the working tree is dirty, so a missed swaggerize run will block the PR.

## Security

- **SSRF protection** - Stream proxy validates HTTPS-only URLs, blocks private IPs (loopback, private ranges, link-local), limits redirect chains to 5 levels
- **Command injection prevention** - All external CLI calls (`fpcalc`, `songrec`, `ffmpeg`, `tesseract`) use array-based `Open3.capture3` instead of shell strings
- **Stream URL privacy** - `direct_stream_url` hidden from public API serializer
- **CORS** - Whitelisted origins via `CORS_ALLOWED_ORIGINS` env var, Netlify preview pattern, and production domain
- **Sidekiq Web UI** - Protected with basic auth. Sidekiq 8 requires session middleware (`ActionDispatch::Cookies` + `Session::CookieStore`) added in `config/application.rb` for API-only apps
