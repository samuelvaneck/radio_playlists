class AddColumnsToPlayedsong < ActiveRecord::Migration
  def change
    add_column :playedsongs, :generalplaylist_id, :integer
    add_column :playedsongs, :song_id, :integer
  end
end
