# frozen_string_literal: true

class AddExtendedAudioFeaturesToMusicProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :music_profiles, :key, :integer
    add_column :music_profiles, :mode, :integer
    add_column :music_profiles, :loudness, :decimal, precision: 5, scale: 2
    add_column :music_profiles, :time_signature, :integer
  end
end
