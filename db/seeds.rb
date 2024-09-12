# frozen_string_literal: true

radio_stations = [
  {
    name: 'Radio 2',
    url: 'https://www.nporadio2.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio2.mp3',
    slug: 'radio-2',
    country_code: 'NLD'
  },
  {
    name: 'Qmusic',
    url: 'https://api.qmusic.nl/2.4/tracks/plays?limit=1&next=true',
    processor: 'qmusic_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/qmusic.mp3',
    slug: 'qmusic',
    country_code: 'NLD'
  },
  {
    name: 'Sublime FM',
    url: 'https://sublime.nl/sublime-playlist/',
    processor: 'scraper',
    stream_url: 'https://icecast.samuelvaneck.com/sublimefm.mp3',
    slug: 'sublime-fm',
    country_code: 'NLD'
  },
  {
    name: 'Radio 5',
    url: 'https://www.nporadio5.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio5.mp3',
    slug: 'radio-5',
    country_code: 'NLD'
  },
  {
    name: 'Radio 3FM',
    url: 'https://www.npo3fm.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio3fm.mp3',
    slug: 'radio-3fm',
    country_code: 'NLD'
  },
  {
    name: 'Radio 1',
    url: 'https://www.nporadio1.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio1.mp3',
    slug: 'radio-1',
    country_code: 'NLD'
  },
  {
    name: 'Groot Nieuws Radio',
    url: 'https://www.grootnieuwsradio.nl/_next/data/qDlbcoGX8H4TWq5datpzf/index.json',
    processor: 'gnr_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/gnr.mp3',
    slug: 'groot-nieuws-radio',
    country_code: 'NLD'
  },
  {
    name: 'Radio 538',
    url: 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-538%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D',
    processor: 'talpa_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio538.mp3',
    slug: 'radio-538',
    country_code: 'NLD'
  },
  {
    name: 'Sky Radio',
    url: 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22sky-radio%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D',
    processor: 'talpa_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/skyradio.mp3',
    slug: 'sky-radio',
    country_code: 'NLD'
  },
  {
    name: 'Radio 10',
    url: 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-10%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D',
    processor: 'talpa_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/radio10.mp3',
    slug: 'radio-10',
    country_code: 'NLD'
  },
  {
    name: 'Radio Veronica',
    url: 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-veronica%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D',
    processor: 'talpa_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/veronica.mp3',
    slug: 'radio-veronica',
    country_code: 'NLD'
  },
  {
    name: 'SLAM!',
    url: 'https://api.slam.nl/api/live?brand=slam',
    processor: 'slam_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/slam.mp3',
    slug: 'slam',
    country_code: 'NLD'
  },
  {
    name: 'KINK',
    url: 'https://api.kink.nl/static/now-playing.json',
    processor: 'kink_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/kink.mp3',
    slug: 'kink',
    country_code: 'NLD'
  },
  {
    name: '100% NL',
    url: 'https://api.100p.nl/api/live?brand=100pnl',
    processor: 'slam_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/100pnl.mp3',
    slug: '100-nl',
    country_code: 'NLD'
  },
  {
    name: 'JOE',
    url: 'https://api.joe.nl/2.0/tracks/plays?limit=1',
    processor: 'qmusic_api_processor',
    stream_url: 'https://icecast.samuelvaneck.com/joe.mp3',
    slug: 'joe',
    country_code: 'NLD'
  },
  {
    name: 'Radio4All',
    url: '',
    processor: '',
    stream_url: 'https://icecast.samuelvaneck.com/radio4all.mp3',
    slug: 'radio4all',
    country_code: 'NLD'
  }
]

radio_stations.each do |radio_station|
  RadioStation.create(radio_station)
end
