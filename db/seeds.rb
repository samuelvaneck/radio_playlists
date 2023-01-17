# frozen_string_literal: true

radio_stations = [
  {
    name: 'Radio 2',
    url: 'https://www.nporadio2.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio2.mp3'
  },
  {
    name: 'Qmusic',
    url: 'https://api.qmusic.nl/2.4/tracks/plays?limit=1&next=true',
    processor: 'qmusic_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/qmusic.mp3'
  },
  {
    name: 'Sublime FM',
    url: 'https://sublime.nl/sublime-playlist/',
    processor: 'scraper',
    stream_url: 'https://icecast.samuelvaneck.com/sublimefm.mp3'
  },
  {
    name: 'Radio 5',
    url: 'https://www.nporadio5.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio5.mp3'
  },
  {
    name: 'Radio 3FM',
    url: 'https://www.npo3fm.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio3fm.mp3'
  },
  {
    name: 'Radio 1',
    url: 'https://www.nporadio1.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio1.mp3'
  },
  {
    name: 'Groot Nieuws Radio',
    url: 'https://www.grootnieuwsradio.nl/muziek/playlist',
    processor: 'scraper',
    stream_url: 'https://icecast.samuelvaneck.com/gnr.mp3'
  },
  {
    name: 'Radio 538',
    processor: 'talpa_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio538.mp3'
  },
  {
    name: 'Sky Radio',
    processor: 'talpa_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/skyradio.mp3'
  },
  {
    name: 'Radio 10',
    processor: 'talpa_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio10.mp3'
  },
  {
    name: 'Radio Veronica',
    processor: 'talpa_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/veronica.mp3'
  },
  {
    name: 'SLAM!',
    url: 'https://api.slam.nl/api/live?brand=slam',
    processor: 'slam_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/slam.mp3'
  }
]

radio_stations.each do |radio_station|
  RadioStation.create(radio_station)
end
