# frozen_string_literal: true

class EnablePgTrgmAndAddTrigramIndexes < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pg_trgm'

    remove_index :songs, :search_text, name: 'index_songs_on_search_text'
    add_index :songs, :search_text, using: :gin, opclass: :gin_trgm_ops, name: 'index_songs_on_search_text_trgm'

    remove_index :artists, :name, name: 'index_artists_on_name'
    add_index :artists, :name, using: :gin, opclass: :gin_trgm_ops, name: 'index_artists_on_name_trgm'
  end
end
