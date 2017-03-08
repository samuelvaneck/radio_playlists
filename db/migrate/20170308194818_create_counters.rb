class CreateCounters < ActiveRecord::Migration[5.0]
  def change
    create_table :counters do |t|
      t.integer :week
      t.integer :month
      t.references :song, foreign_key: true

      t.timestamps
    end
  end
end
