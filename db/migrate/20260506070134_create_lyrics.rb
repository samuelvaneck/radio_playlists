class CreateLyrics < ActiveRecord::Migration[8.1]
  def change
    create_table :lyrics do |t|
      t.references :song, null: false, foreign_key: true, index: { unique: true }
      t.decimal :sentiment, precision: 3, scale: 2
      t.string :themes, array: true, default: []
      t.string :language, limit: 8
      t.string :source, default: 'lrclib', null: false
      t.string :source_url
      t.string :source_id
      t.datetime :enriched_at

      t.timestamps
    end

    add_index :lyrics, :themes, using: :gin
    add_index :lyrics, :sentiment
    add_index :lyrics, :enriched_at
  end
end
