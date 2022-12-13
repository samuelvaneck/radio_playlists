# frozen_string_literal: true

class AddStreamUrlToRadioStation < ActiveRecord::Migration[7.0]
  def change
    add_column :radio_stations, :stream_url, :string

    updates = [{
      name: 'Radio 2',
      stream_url: 'https://icecast.omroep.nl/radio2-bb-mp3'
    },
    {
      name: 'Qmusic',
      stream_url: 'https://icecast-qmusicnl-cdp.triple-it.nl/Qmusic_nl_live_96.mp3'
    },
    {
      name: 'Sublime FM',
      stream_url: 'https://25323.live.streamtheworld.com/SUBLIME.mp3'
    },
    {
      name: 'Radio 5',
      stream_url: 'https://icecast.omroep.nl/radio5-bb-mp3'
     },
    {
      name: 'Radio 3FM',
      stream_url: 'https://icecast.omroep.nl/3fm-bb-mp3'
    },
    {
      name: 'Radio 1',
      stream_url: '	https://icecast.omroep.nl/radio1-bb-mp3'
    },
    {
      name: 'Groot Nieuws Radio',
      stream_url: 'https://25433.live.streamtheworld.com/GNRAAC/HLS/f673ca59-86ac-4046-8071-c68913685292/0/playlist.m3u8'
    },
    {
      name: 'Radio 538',
      stream_url: 'https://25593.live.streamtheworld.com/RADIO538.mp3'
    },
    {
      name: 'Sky Radio',
      stream_url: 'https://22543.live.streamtheworld.com/SKYRADIO.mp3'
    },
    {
      name: 'Radio 10',
      stream_url: 'https://25273.live.streamtheworld.com/RADIO10.mp3'
    },
    {
      name: 'Radio Veronica',
      stream_url: 'https://25243.live.streamtheworld.com/VERONICA.mp3'
    }]

    updates.each do |update|
      RadioStation.find_by(name: update[:name]).update(stream_url: update[:stream_url])
    end
  end
end
