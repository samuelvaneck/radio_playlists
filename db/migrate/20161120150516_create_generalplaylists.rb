class CreateGeneralplaylists < ActiveRecord::Migration
  def change
    create_table :generalplaylists do |t|
      t.datetime :created_at

      t.timestamps null: false
    end
  end
end
