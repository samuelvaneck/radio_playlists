class AddLastfmFieldsToSongs < ActiveRecord::Migration[8.0]
  def change
    add_column :songs, :lastfm_url, :string
    add_column :songs, :lastfm_listeners, :integer
    add_column :songs, :lastfm_playcount, :integer
    add_column :songs, :lastfm_tags, :jsonb
    add_column :songs, :lastfm_mbid, :string
  end
end
