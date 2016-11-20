class CreatePlayedsongs < ActiveRecord::Migration
  def change
    create_table :playedsongs do |t|

      t.timestamps null: false
    end
  end
end
