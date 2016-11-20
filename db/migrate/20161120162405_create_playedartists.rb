class CreatePlayedartists < ActiveRecord::Migration
  def change
    create_table :playedartists do |t|

      t.timestamps null: false
    end
  end
end
