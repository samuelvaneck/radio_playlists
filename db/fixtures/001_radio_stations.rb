# frozen_string_literal: true

RadioStation.seed(
  :name,
  :country_code,
  {
    name: 'Radio 2',
    url: 'https://www.nporadio2.nl/api/tracks',
    processor: 'npo_api_processor',
    direct_stream_url: 'https://icecast.omroep.nl/radio2-bb-mp3',
    slug: 'radio-2',
    country_code: 'NLD'
  },
  {
    name: 'Qmusic',
    url: 'https://api.qmusic.nl/2.4/tracks/plays?limit=1&next=true',
    processor: 'qmusic_api_processor',
    direct_stream_url: 'https://stream.qmusic.nl/qmusic/mp3',
    slug: 'qmusic',
    country_code: 'NLD'
  },
  {
    name: 'Sublime FM',
    url: 'https://api.mediahuisradio.nl/api/nowplaying/playlist?stationKey=sublime&brand=sublime',
    processor: 'media_huis_api_processor',
    direct_stream_url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/SUBLIME.mp3',
    slug: 'sublime-fm',
    country_code: 'NLD'
  },
  {
    name: 'Radio 5',
    url: 'https://www.nporadio5.nl/api/tracks',
    processor: 'npo_api_processor',
    direct_stream_url: 'https://icecast.omroep.nl/radio5-bb-mp3',
    slug: 'radio-5',
    country_code: 'NLD'
  },
  {
    name: 'Radio 3FM',
    url: 'https://www.npo3fm.nl/api/tracks',
    processor: 'npo_api_processor',
    direct_stream_url: 'https://icecast.omroep.nl/3fm-bb-mp3',
    slug: 'radio-3fm',
    country_code: 'NLD'
  },
  {
    name: 'Radio 1',
    url: 'https://www.nporadio1.nl/api/tracks',
    processor: 'npo_api_processor',
    direct_stream_url: 'https://icecast.omroep.nl/radio1-bb-mp3',
    slug: 'radio-1',
    country_code: 'NLD'
  },
  {
    name: 'Groot Nieuws Radio',
    url: 'https://api.grootnieuwsradio.nl/static/now-playing.json',
    processor: 'gnr_api_processor',
    direct_stream_url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/GNR.mp3',
    slug: 'groot-nieuws-radio',
    country_code: 'NLD'
  },
  {
    name: 'Radio 538',
    url: 'https://graph.talparad.io/?query=query+CurrentTrackQuery%28%24stationSlug%3AString%21%29%7Bstation%28slug%3A%24stationSlug%29%7BgetPlayouts%7Bplayouts%7Btrack%7Bid+title+artistName+isrc+images%7Buri+imageType+title%7D%7Drankings%7Bposition+listName%7D%7D%7D%7D%7D&variables=%7B%22stationSlug%22%3A%22radio-538%22%7D',
    processor: 'talpa_api_processor',
    direct_stream_url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/RADIO538.mp3',
    slug: 'radio-538',
    country_code: 'NLD'
  },
  {
    name: 'Sky Radio',
    url: 'https://graph.talparad.io/?query=query+CurrentTrackQuery%28%24stationSlug%3AString%21%29%7Bstation%28slug%3A%24stationSlug%29%7BgetPlayouts%7Bplayouts%7Btrack%7Bid+title+artistName+isrc+images%7Buri+imageType+title%7D%7Drankings%7Bposition+listName%7D%7D%7D%7D%7D&variables=%7B%22stationSlug%22%3A%22sky-radio%22%7D',
    processor: 'talpa_api_processor',
    direct_stream_url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/SKYRADIO.mp3',
    slug: 'sky-radio',
    country_code: 'NLD'
  },
  {
    name: 'Radio 10',
    url: 'https://graph.talparad.io/?query=query+CurrentTrackQuery%28%24stationSlug%3AString%21%29%7Bstation%28slug%3A%24stationSlug%29%7BgetPlayouts%7Bplayouts%7Btrack%7Bid+title+artistName+isrc+images%7Buri+imageType+title%7D%7Drankings%7Bposition+listName%7D%7D%7D%7D%7D&variables=%7B%22stationSlug%22%3A%22radio-10%22%7D',
    processor: 'talpa_api_processor',
    direct_stream_url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/RADIO10.mp3',
    slug: 'radio-10',
    country_code: 'NLD'
  },
  {
    name: 'Radio Veronica',
    url: 'https://api.radioveronica.nl/api/nowplaying/playlist?stationKey=veronica&brand=veronica',
    processor: 'media_huis_api_processor',
    direct_stream_url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/VERONICA.mp3',
    slug: 'radio-veronica',
    country_code: 'NLD'
  },
  {
    name: 'SLAM!',
    url: 'https://api.radioveronica.nl/api/nowplaying/playlist?stationKey=slam&brand=slam',
    processor: 'media_huis_api_processor',
    direct_stream_url: 'https://stream.slam.nl/slam_mp3',
    slug: 'slam',
    country_code: 'NLD'
  },
  {
    name: 'KINK',
    url: 'https://api.kink.nl/static/now-playing.json',
    processor: 'kink_api_processor',
    direct_stream_url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/KINK.mp3',
    slug: 'kink',
    country_code: 'NLD'
  },
  {
    name: '100% NL',
    url: 'https://api.radioveronica.nl/api/nowplaying/playlist?stationKey=100pnl&brand=100nl',
    processor: 'media_huis_api_processor',
    direct_stream_url: 'https://stream.100p.nl/100pctnl.mp3',
    slug: '100-nl',
    country_code: 'NLD'
  },
  {
    name: 'JOE',
    url: 'https://api.joe.nl/2.0/tracks/plays?limit=1',
    processor: 'qmusic_api_processor',
    direct_stream_url: 'https://stream.joe.nl/joe/mp3',
    slug: 'joe',
    country_code: 'NLD'
  },
  {
    name: 'Yoursafe Radio',
    url: 'https://4e2623dcced8.eu-central-1.playback.live-video.net/api/video/v1/eu-central-1.384301552878.channel.qoqD1R97L2kw.m3u8',
    processor: 'yoursafe_video_processor',
    direct_stream_url: 'https://4e2623dcced8.eu-central-1.playback.live-video.net/api/video/v1/eu-central-1.384301552878.channel.qoqD1R97L2kw.m3u8',
    slug: 'yoursafe-radio',
    country_code: 'NLD'
  },
  {
    name: 'Jumbo Radio',
    url: '',
    processor: '',
    direct_stream_url: 'https://streams.automates.media/jumboradio',
    slug: 'jumbo-radio',
    country_code: 'NLD'
  },
  {
    name: 'Arrow Classic Rock',
    url: 'https://www.arrow.nl/wp-content/plugins/adeko-arrow-onair/playlistdata/Arrow_PLAYING_NOW.json',
    processor: 'arrow_api_processor',
    direct_stream_url: 'https://stream.player.arrow.nl/arrow',
    slug: 'arrow-classic-rock',
    country_code: 'NLD'
  },
  {
    name: 'FunX',
    url: 'https://www.funx.nl/api/tracks',
    processor: 'npo_api_processor',
    direct_stream_url: 'https://icecast.omroep.nl/funx-bb-mp3',
    slug: 'funx',
    country_code: 'NLD'
  },
  {
    name: 'Decibel',
    direct_stream_url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/RADIODECIBEL.mp3',
    slug: 'decibel',
    country_code: 'NLD'
  },
  {
    name: 'Simone FM',
    url: 'https://api01.simone.nl/playlist?station=SIMONEFM',
    processor: 'simone_api_processor',
    direct_stream_url: 'https://stream.simone.nl/simone',
    slug: 'simone-fm',
    country_code: 'NLD'
  }
)
