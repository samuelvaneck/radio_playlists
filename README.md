# Radio Playlists

Radio Playlists is a Ruby on Rails application designed listen to and process the latest played songs from various radio stations. The application integrates with multiple APIs and web scraping tools to fetch and display real-time playlist data.

## Features

- **API Integration**: Supports multiple radio station APIs (e.g., Talpa, Qmusic, SLAM!, KINK).
- **Web Scraping**: Scrapes playlist data for stations without APIs.
- **Real-Time Updates**: Fetches the latest played songs with timestamps.
- **Error Handling**: Logs errors and notifies monitoring tools (e.g., New Relic) for failed requests.
- **Extensible Architecture**: Easily add support for new radio stations.

## Technologies Used

- **Backend**: Ruby on Rails
- **Frontend**: React
- **Testing**: RSpec
- **Package Management**: Yarn, npm, Bundler
- **Database**: PostgreSQL (or other supported databases)
- **Song Recognition**: SongRec
- **Song enrichment**: Spotify API, Last.fm API
- **Audio Processing**: FFMpeg
- **Sidekiq**: For background job processing
- **Monitoring**: New Relic
- **Web Scraping**: Nokogiri

## Setup Instructions

### Prerequisites

- Ruby (version specified in `.ruby-version`)
- Rails (version specified in `Gemfile`)
- Node.js and npm
- Yarn
- PostgreSQL

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/samuelvaneck/radio_playlists.git
   cd radio_playlists# radio_playlists
   ```
2. Install Ruby gems:
   ```bash
   bundle install
   ```
3. Install SongRec:
   Follow the installation on https://github.com/marin-m/SongRec
4. Install FFMpeg:
   Follow the installation on https://ffmpeg.org/download.html
5. Set up Last.fm API credentials (optional):
   - Get an API key from https://www.last.fm/api/account/create
   - Set environment variables:
     ```bash
     export LASTFM_API_KEY=your_api_key
     export LASTFM_API_SECRET=your_api_secret
     ```
6. Create, migrate and seed the database:
   ```bash
   rails db:create
   rails db:schema:load
   rails db:seed
   ```
7. Start  the Rails server:
   ```bash
   rails server
   ```
8. Start the Sidekiq worker:
   ```bash
    bundle exec sidekiq
    ```
   
OR 

Run the code in docker
   ```bash
   docker-compose up
   ```
