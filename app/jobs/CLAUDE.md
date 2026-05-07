# Background Jobs

Guidance for `app/jobs/`. The root `CLAUDE.md` has project-wide context.

## Sidekiq Queues

Three queues, each served by a dedicated Sidekiq worker in production so a flood of one workload can never starve another:

| Queue | Workload | Worker concurrency (prod) |
|---|---|---|
| `realtime` | API scraping, audio recognition, per-station imports — keeps up with stations playing | 10 (I/O-bound, GIL released on socket waits) |
| `compute` | Chart generation, VACUUM, log/draft cleanup, monitoring — CPU/DB-heavy, scheduled at off-peak | 3 (heavy SQL aggregation; more threads only multiply DB load) |
| `enrichment` | Spotify/Deezer/iTunes/Tidal external IDs, Last.fm, MusicBrainz, music profile, AcoustID — slow per-record fan-out | 5 (HTTP fan-out balanced against DB pool) |

## Scheduled Jobs

Jobs in `app/jobs/` run on schedules defined in `config/sidekiq.yml`:
- `ImportSongsAllRadioStationsJob` (`realtime`) - Every minute, imports songs from all stations
- `ChartCreationJob` (`compute`) - Daily at 00:10, generates charts
- `ChartSongEnrichmentJob` (`enrichment`) - Daily at 00:30, re-enriches charted songs with latest Last.fm/Spotify data for popularity boost
- `YoutubeApiImportJob` (`realtime`) - Every 15 minutes
- `CleanupDraftAirPlaysJob` (`compute`) - Every hour, cleans draft airplays older than 4 hours and orphaned SongImportLogs
- `SongImportMonitorJob` (`compute`) - Every hour, monitors import failure rates and alerts
- `SongImportLogCleanupJob` (`compute`) - Daily at 2am, exports and deletes old import logs
- `DatabaseVacuumJob` (`compute`) - Daily at 3am, runs VACUUM ANALYZE on key tables to prevent bloat
- `AvgSongGapCalculationJob` (`compute`) - Daily at 5am, calculates per-station average song gaps
- `ArtistEnrichmentBatchJob` (`enrichment`) - Weekly Sunday 3am, batch enqueues artist enrichment
- `LastfmEnrichmentBatchJob` (`enrichment`) - Weekly Sunday 4am, batch enqueues Last.fm enrichment for songs/artists
- `LyricsEnrichmentBatchJob` (`enrichment`) - Weekly Sunday 5am, batch enqueues lyrics-sentiment enrichment for recently-played songs (gated by `LYRICS_ENRICHMENT_ENABLED`)

## On-Demand Jobs

On-demand enrichment jobs (triggered by import flow, not scheduled — all on the `enrichment` queue):
- `SongExternalIdsEnrichmentJob` - Enriches songs with Deezer, iTunes, and MusicBrainz IDs after import
- `ArtistExternalIdsEnrichmentJob` - Enriches artists with Tidal, Deezer, and iTunes IDs after import
- `MusicProfileJob` - Creates Spotify audio feature profiles for songs, then calculates `hit_potential_score` via `HitPotentialCalculator`
- `AcoustidPopulationJob` - Downloads YouTube audio, generates fingerprints, submits to AcoustID

**Important:** `ImportSongJob` uses `sidekiq-unique-jobs` with `lock: :until_executed` and `lock_ttl: 90`, plus a 60-second `Timeout.timeout` wrapper around `SongImporter#import`. The wall-clock timeout caps each job at one minute (covering edge-case hangs not handled by inner subprocess/HTTP timeouts), and `lock_ttl` is set higher than the timeout so the unique lock spans the full execution — otherwise the per-minute scheduler would enqueue duplicates while a slow job is still running, and they would pile up across worker threads.

## Sidekiq Memory Monitor

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
