class AddColumnsToPlayedartist < ActiveRecord::Migration
  def change
    add_column :playedartists, :artist_id, :integer
    add_column :playedartists, :generalplaylist_id, :integer
  end
end
