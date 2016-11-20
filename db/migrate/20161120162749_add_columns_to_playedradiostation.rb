class AddColumnsToPlayedradiostation < ActiveRecord::Migration
  def change
    add_column :playedradiostations, :generalplaylist_id, :integer
    add_column :playedradiostations, :radiostation_id, :integer
  end
end
