class AddLastfmDataToSongsAndArtists < ActiveRecord::Migration[8.1]
  def change
    change_table :artists, bulk: true do |t|
      t.bigint :lastfm_listeners
      t.bigint :lastfm_playcount
      t.string :lastfm_tags, array: true, default: []
      t.datetime :lastfm_enriched_at
    end

    change_table :songs, bulk: true do |t|
      t.bigint :lastfm_listeners
      t.bigint :lastfm_playcount
      t.string :lastfm_tags, array: true, default: []
      t.datetime :lastfm_enriched_at
    end
  end
end
