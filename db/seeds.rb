# frozen_string_literal: true

radio_stations = [
  {
    name: 'Radio 2',
    url: 'https://www.nporadio2.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.omroep.nl/radio2-bb-mp3'
  },
  {
    name: 'Qmusic',
    url: 'https://api.qmusic.nl/2.4/tracks/plays?limit=1&next=true',
    processor: 'qmusic_api_processor',
    stream_url: 'https://icecast-qmusicnl-cdp.triple-it.nl/Qmusic_nl_live_96.mp3'
  },
  {
    name: 'Sublime FM',
    url: 'https://sublime.nl/sublime-playlist/',
    processor: 'scraper',
    stream_url: 'https://25323.live.streamtheworld.com/SUBLIME.mp3'
  },
  {
    name: 'Radio 5',
    url: 'https://www.nporadio5.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.omroep.nl/radio5-bb-mp3'
   },
  {
    name: 'Radio 3FM',
    url: 'https://www.npo3fm.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: 'https://icecast.omroep.nl/3fm-bb-mp3'
  },
  {
    name: 'Radio 1',
    url: 'https://www.nporadio1.nl/api/tracks',
    processor: 'npo_api_processor',
    stream_url: '	https://icecast.omroep.nl/radio1-bb-mp3'
  },
  {
    name: 'Groot Nieuws Radio',
    url: 'https://www.grootnieuwsradio.nl/muziek/playlist',
    processor: 'scraper',
    stream_url: 'https://25433.live.streamtheworld.com/GNRAAC/HLS/f673ca59-86ac-4046-8071-c68913685292/0/playlist.m3u8'
  },
  {
    name: 'Radio 538',
    url: 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-538%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D',
    processor: 'talpa_api_processor',
    stream_url: 'https://25593.live.streamtheworld.com/RADIO538.mp3'
  },
  {
    name: 'Sky Radio',
    url: 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22sky-radio%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D',
    processor: 'talpa_api_processor',
    stream_url: 'https://22543.live.streamtheworld.com/SKYRADIO.mp3'
  },
  {
    name: 'Radio 10',
    url: 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-10%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D',
    processor: 'talpa_api_processor',
    stream_url: 'https://25273.live.streamtheworld.com/RADIO10.mp3'
  },
  {
    name: 'Radio Veronica',
    url: 'https://graph.talparad.io/?query=%7B%0A%20%20getStation(profile%3A%20%22radio-brand-web%22%2C%20slug%3A%20%22radio-veronica%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20playouts(profile%3A%20%22%22%2C%20limit%3A%2010)%20%7B%0A%20%20%20%20%20%20broadcastDate%0A%20%20%20%20%20%20track%20%7B%0A%20%20%20%20%20%20%20%20id%0A%20%20%20%20%20%20%20%20title%0A%20%20%20%20%20%20%20%20artistName%0A%20%20%20%20%20%20%20%20isrc%0A%20%20%20%20%20%20%20%20images%20%7B%0A%20%20%20%20%20%20%20%20%20%20type%0A%20%20%20%20%20%20%20%20%20%20uri%0A%20%20%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20%20%20__typename%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20__typename%0A%20%20%20%20%7D%0A%20%20%20%20__typename%0A%20%20%7D%0A%7D%0A&variables=%7B%7D',
    processor: 'talpa_api_processor',
    stream_url: 'https://25243.live.streamtheworld.com/VERONICA.mp3'
  }
]

radio_stations.each do |radio_station|
  RadioStation.create(radio_station)
end
