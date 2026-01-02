# frozen_string_literal: true

class CreateMusicProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :music_profiles do |t|
      t.references :song, null: false, foreign_key: true, index: { unique: true }
      t.decimal :danceability, precision: 5, scale: 4
      t.decimal :energy, precision: 5, scale: 4
      t.decimal :speechiness, precision: 5, scale: 4
      t.decimal :acousticness, precision: 5, scale: 4
      t.decimal :instrumentalness, precision: 5, scale: 4
      t.decimal :liveness, precision: 5, scale: 4
      t.decimal :valence, precision: 5, scale: 4
      t.decimal :tempo, precision: 6, scale: 2

      t.timestamps
    end
  end
end
