class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.integer :counter, default: 0
      t.references :taggable, polymorphic: true, null: false
      t.index %i[name taggable_id taggable_type], unique: true

      t.timestamps
    end
  end
end
