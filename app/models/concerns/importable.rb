# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

module Importable
  extend ActiveSupport::Concern
  include TrackDataProcessor

  # Methode for creating the Generalplaylist record
  def create_generalplaylist(broadcast_timestamp, artists, song, radio_station)
    last_played_song = Generalplaylist.where(radiostation: radio_station, song:, broadcast_timestamp:).order(created_at: :desc).first

    if last_played_song.blank?
      add_song(broadcast_timestamp, artists, song, radio_station)
    elsif last_played_song.broadcast_timestamp == broadcast_timestamp && last_played_song.song == song
      puts "#{song.title} from #{Array.wrap(artists).map(&:name).join(', ')} last song on #{radio_station.name}"
    else
      puts 'No song added'
    end
  end

  # Methode for adding the song to the database
  def add_song(broadcast_timestamp, artists, song, radio_station)
    fullname = "#{Array.wrap(artists).map(&:name).join(' ')} #{song.title}"
    # Create a new Generalplaylist record
    Generalplaylist.create(
      broadcast_timestamp:,
      song:,
      radiostation: radio_station
    )
    song.update(fullname:)

    # cleaning up artists
    song.artists.clear
    Array.wrap(artists).each do |artist|
      next if song.artists.include? artist

      song.artists << artist
    end

    artists_names = Array.wrap(artists).map(&:name).join(', ')
    artists_ids = Array.wrap(artists).map(&:id).join(' ')
    puts "Saved #{song.title} (#{song.id}) from #{artists_names} (#{artists_ids}) on #{radio_station.name}!"
  end
end
