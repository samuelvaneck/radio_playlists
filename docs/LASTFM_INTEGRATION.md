# Last.fm API Integration

This document describes the Last.fm API integration for the Radio Playlists application.

## Overview

The Last.fm integration provides additional metadata and enrichment for songs and artists, including:
- Play counts and listener statistics
- Music tags and genres
- Similar tracks and artists
- Artist biographies
- MusicBrainz IDs (MBIDs)

## Configuration

### API Credentials

1. Obtain API credentials from [Last.fm API](https://www.last.fm/api/account/create)
2. Set environment variables:
   ```bash
   export LASTFM_API_KEY=your_api_key
   export LASTFM_API_SECRET=your_api_secret
   ```

3. Or add to your `.env` file:
   ```
   LASTFM_API_KEY=your_api_key
   LASTFM_API_SECRET=your_api_secret
   ```

### Database Setup

Run migrations to add Last.fm fields:
```bash
rails db:migrate
```

This adds the following fields:
- **Songs**: `lastfm_url`, `lastfm_listeners`, `lastfm_playcount`, `lastfm_tags`, `lastfm_mbid`
- **Artists**: `lastfm_url`, `lastfm_listeners`, `lastfm_playcount`, `lastfm_tags`, `lastfm_mbid`, `lastfm_bio`

## Usage

### Service Classes

#### Authentication (`Lastfm::Auth`)
Handles API authentication and request management:
```ruby
auth = Lastfm::Auth.new
auth.valid_credentials? # Check if credentials are configured
```

#### Track Finder (`Lastfm::TrackFinder`)
Search and retrieve track information:
```ruby
finder = Lastfm::TrackFinder.new

# Search for tracks
results = finder.search('The Beatles', 'Hey Jude', limit: 10)

# Get detailed track info
info = finder.get_info('The Beatles', 'Hey Jude')

# Find similar tracks
similar = finder.get_similar('The Beatles', 'Hey Jude')

# Get track tags
tags = finder.get_top_tags('The Beatles', 'Hey Jude')
```

#### Artist Finder (`Lastfm::ArtistFinder`)
Search and retrieve artist information:
```ruby
finder = Lastfm::ArtistFinder.new

# Search for artists
results = finder.search('The Beatles', limit: 10)

# Get detailed artist info
info = finder.get_info('The Beatles')

# Find similar artists
similar = finder.get_similar('The Beatles')

# Get top tracks
tracks = finder.get_top_tracks('The Beatles')

# Get top albums
albums = finder.get_top_albums('The Beatles')

# Get artist tags
tags = finder.get_top_tags('The Beatles')
```

#### Song Enricher (`Lastfm::SongEnricher`)
High-level service for enriching songs and artists:
```ruby
enricher = Lastfm::SongEnricher.new

# Enrich a song with Last.fm data
song = Song.find(123)
enricher.enrich_song(song)

# Enrich an artist
artist = Artist.find(456)
enricher.enrich_artist(artist)

# Search for tracks
results = enricher.search_tracks('Beatles - Hey Jude')

# Search for artists
results = enricher.search_artists('The Beatles')

# Get similar tracks for a song
similar = enricher.get_similar_tracks(song)

# Get similar artists
similar = enricher.get_similar_artists(artist)
```

### Rake Tasks

Several rake tasks are available for Last.fm operations:

```bash
# Test API connection
rails lastfm:test_connection

# Enrich songs with Last.fm data (processes up to 100 songs)
rails lastfm:enrich_songs

# Enrich artists with Last.fm data (processes up to 100 artists)
rails lastfm:enrich_artists

# Search for a track
rails lastfm:search_track['The Beatles - Hey Jude']

# Search for an artist
rails lastfm:search_artist['The Beatles']
```

### Integration with Existing Code

You can integrate Last.fm enrichment into existing song import workflows:

```ruby
# In a song importer service
def import_song(song_data)
  song = Song.create!(song_data)
  
  # Enrich with Spotify data
  spotify_enricher.enrich(song)
  
  # Enrich with Last.fm data
  lastfm_enricher = Lastfm::SongEnricher.new
  lastfm_enricher.enrich_song(song)
  
  song
end
```

### Background Jobs

For large-scale enrichment, consider using background jobs:

```ruby
class LastfmEnrichmentJob < ApplicationJob
  def perform(song_id)
    song = Song.find(song_id)
    enricher = Lastfm::SongEnricher.new
    enricher.enrich_song(song)
  end
end

# Queue enrichment for new songs
Song.where(lastfm_url: nil).find_each do |song|
  LastfmEnrichmentJob.perform_later(song.id)
end
```

## API Rate Limits

Last.fm API has the following rate limits:
- 5 requests per second per API key
- No daily limit for non-commercial use

The services include automatic error handling and logging for rate limit issues.

## Testing

Run the Last.fm service tests:
```bash
bundle exec rspec spec/services/lastfm/
```

Tests use WebMock to stub API requests, so no actual API calls are made during testing.

## Data Fields

### Song Fields
- `lastfm_url`: Direct URL to the track on Last.fm
- `lastfm_listeners`: Number of unique listeners
- `lastfm_playcount`: Total play count
- `lastfm_tags`: Array of music tags/genres
- `lastfm_mbid`: MusicBrainz ID for cross-referencing

### Artist Fields
- `lastfm_url`: Direct URL to the artist on Last.fm
- `lastfm_listeners`: Number of unique listeners
- `lastfm_playcount`: Total play count across all tracks
- `lastfm_tags`: Array of music tags/genres
- `lastfm_mbid`: MusicBrainz ID for cross-referencing
- `lastfm_bio`: Artist biography summary

## Error Handling

All services include comprehensive error handling:
- Network errors are caught and logged
- API errors are logged with details
- Methods return `nil` on errors rather than raising exceptions
- All errors are logged to Rails logger for monitoring

## Examples

### Complete Enrichment Workflow
```ruby
# Find songs without Last.fm data
songs_to_enrich = Song.includes(:artists)
                      .where(lastfm_url: nil)
                      .where.not(artists: { id: nil })

enricher = Lastfm::SongEnricher.new

songs_to_enrich.find_each do |song|
  # Enrich the song
  enricher.enrich_song(song)
  
  # Also enrich associated artists
  song.artists.each do |artist|
    enricher.enrich_artist(artist) if artist.lastfm_url.blank?
  end
  
  # Rate limiting
  sleep 0.2
end
```

### Finding Similar Music
```ruby
song = Song.find_by(title: 'Hey Jude')
enricher = Lastfm::SongEnricher.new

# Get similar tracks
similar_tracks = enricher.get_similar_tracks(song, limit: 5)

similar_tracks.each do |track|
  puts "#{track[:artist][:name]} - #{track[:name]} (Match: #{track[:match]})"
end

# Get similar artists
artist = song.artists.first
similar_artists = enricher.get_similar_artists(artist, limit: 5)

similar_artists.each do |similar|
  puts "#{similar[:name]} (Match: #{similar[:match]})"
end
```

## Monitoring

Monitor Last.fm integration health:
- Check for songs/artists with `lastfm_url: nil` to identify unenriched content
- Monitor Rails logs for Last.fm API errors
- Use `rails lastfm:test_connection` to verify API connectivity

## Future Enhancements

Potential improvements to consider:
- Caching API responses to reduce duplicate requests
- Batch processing for bulk enrichment
- Webhook integration for real-time updates
- User scrobbling integration
- Chart data integration