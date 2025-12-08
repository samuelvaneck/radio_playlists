class AddLastfmFieldsToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :lastfm_url, :string
    add_column :artists, :lastfm_listeners, :integer
    add_column :artists, :lastfm_playcount, :integer
    add_column :artists, :lastfm_tags, :jsonb
    add_column :artists, :lastfm_mbid, :string
    add_column :artists, :lastfm_bio, :text
  end
end
