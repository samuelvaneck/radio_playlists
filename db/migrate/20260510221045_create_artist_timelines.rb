# frozen_string_literal: true

class CreateArtistTimelines < ActiveRecord::Migration[8.1]
  def change
    create_table :artist_timelines do |t|
      t.references :artist, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :events, null: false, default: []
      t.string :musicbrainz_id
      t.string :wikidata_id
      t.boolean :llm_enriched, null: false, default: false
      t.datetime :fetched_at

      t.timestamps
    end

    add_index :artist_timelines, :fetched_at
  end
end
