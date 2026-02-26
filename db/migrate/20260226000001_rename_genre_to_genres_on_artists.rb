# frozen_string_literal: true

class RenameGenreToGenresOnArtists < ActiveRecord::Migration[8.1]
  def change
    remove_column :artists, :genre, :string
    add_column :artists, :genres, :string, array: true, default: []
  end
end
