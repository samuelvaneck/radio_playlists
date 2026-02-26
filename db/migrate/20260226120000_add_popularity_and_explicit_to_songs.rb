class AddPopularityAndExplicitToSongs < ActiveRecord::Migration[8.1]
  def change
    change_table :songs, bulk: true do |t|
      t.integer :popularity
      t.boolean :explicit, default: false
    end
  end
end
