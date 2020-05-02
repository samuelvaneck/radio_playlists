# frozen_string_literal: true

class RemoveUnusedAttributes < ActiveRecord::Migration[6.0]
  def change
    remove_column :songs, :song_preview
    remove_column :songs, :artwork_url
    remove_column :songs, :day_counter
    remove_column :songs, :week_counter
    remove_column :songs, :month_counter
    remove_column :songs, :year_counter
    remove_column :songs, :total_counter

    remove_column :artists, :day_counter
    remove_column :artists, :week_counter
    remove_column :artists, :month_counter
    remove_column :artists, :year_counter
    remove_column :artists, :total_counter
  end
end
