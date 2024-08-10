class CreateRadioStationSongs < ActiveRecord::Migration[7.1]
  def change
    create_table :radio_station_songs do |t|
      t.references :song, null: false, foreign_key: true
      t.references :radio_station, null: false, foreign_key: true
      t.datetime :first_broadcasted_at
    end

    add_index :radio_station_songs, %i[song_id radio_station_id], unique: true

    RadioStation.all.each do |radio_station|
      radio_station.songs.distinct.find_in_batches do |songs|
        songs.each do |song|
          RadioStationSong.create(
            song: song,
            radio_station: radio_station,
            first_broadcasted_at: song.playlists.where(radio_station: radio_station).pluck(:broadcasted_at).min
          )
        end
      end
    end
  end
end
