class CreateGeneralplaylists < ActiveRecord::Migration
  def change
    create_table :generalplaylists do |t|
      t.string :time

      t.timestamps null: false
    end
  end
end
