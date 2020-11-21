# frozen_string_literal: true

class Generalplaylist < ActiveRecord::Base
  belongs_to :song
  belongs_to :radiostation
  has_many :artists, through: :song

  validate :today_unique_playlist_item

  include Importable

  ###########
  ### NPO ###
  ###########

  def self.radio_1_check
    radio_station = Radiostation.find_by(name: 'Radio 1')
    import_song(radio_station)
  end
  
  def self.radio_2_check
    radio_station = Radiostation.find_by(name: 'Radio 2')
    import_song(radio_station)
  end

  def self.radio_3fm_check
    radio_station = Radiostation.find_by(name: 'Radio 3FM')
    import_song(radio_station)
  end

  def self.radio_5_check
    radio_station = Radiostation.find_by(name: 'Radio 5')
    import_song(radio_station)
  end

  #############
  ### TALPA ###
  #############

  def self.sky_radio_check
    radio_station = Radiostation.find_by(name: 'Sky Radio')
    import_song(radio_station)
  end

  # Check the Radio Veronica song
  def self.radio_veronica_check
    radio_station = Radiostation.find_by(name: 'Radio Veronica')
    import_song(radio_station)
  end

  # Check the Radio 538 song
  def self.radio_538_check
    radio_station = Radiostation.find_by(name: 'Radio 538')
    import_song(radio_station)
  end

  def self.radio_10_check
    radio_station = Radiostation.find_by(name: 'Radio 10')
    import_song(radio_station)
  end

  #############
  ### OTHER ###
  #############

  def self.q_music_check
    radio_station = Radiostation.find_by(name: 'Qmusic')
    import_song(radio_station)
  end

  # Check Sublime FM songs
  def self.sublime_fm_check
    radio_station = Radiostation.find_by(name: 'Sublime FM')
    import_song(radio_station)
  end

  # Check Groot Nieuws Radio songs
  def self.grootnieuws_radio_check
    radio_station = Radiostation.find_or_create_by(name: 'Groot Nieuws Radio')
    import_song(radio_station)
  end

  def self.check_all_radiostations
    # npo stations
    radio_1_check
    radio_2_check
    radio_3fm_check
    radio_5_check
    # talpa station
    radio_538_check
    sky_radio_check
    radio_veronica_check
    radio_10_check
    # other stations
    q_music_check
    sublime_fm_check
    grootnieuws_radio_check
  end

  def self.search(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time =  params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    playlists = Generalplaylist.joins(:song, :artists).order(created_at: :DESC)
    playlists.where!('songs.title ILIKE ? OR artists.name ILIKE ?', "%#{params[:search_term]}%", "%#{params[:search_term]}%") if params[:search_term].present?
    playlists.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    playlists.where!('generalplaylists.created_at > ?', start_time)
    playlists.where!('generalplaylists.created_at < ?', end_time)
    playlists.uniq
  end

  private

  def today_unique_playlist_item
    exisiting_record = Generalplaylist.joins(:song, :radiostation).where('songs.id = ? AND broadcast_timestamp = ? AND radiostations.id = ?', song_id, broadcast_timestamp, radiostation_id).present?
    errors.add(:base, 'none unique playlist') if exisiting_record
  end
end
