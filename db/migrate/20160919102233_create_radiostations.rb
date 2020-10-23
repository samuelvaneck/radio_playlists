class CreateRadiostations < ActiveRecord::Migration[5.1]
  def change
    create_table :radiostations do |t|
      t.string :name
      t.string :genre

      t.timestamps :null => false
    end
  end
end
