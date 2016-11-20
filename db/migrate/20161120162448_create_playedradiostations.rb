class CreatePlayedradiostations < ActiveRecord::Migration
  def change
    create_table :playedradiostations do |t|

      t.timestamps null: false
    end
  end
end
