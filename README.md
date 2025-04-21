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
- **Song enrichment**: Spotify API
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
