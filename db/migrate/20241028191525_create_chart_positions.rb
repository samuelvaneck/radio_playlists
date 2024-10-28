class CreateChartPositions < ActiveRecord::Migration[7.2]
  def change
    create_table :chart_positions do |t|
      t.bigint :position, null: false
      t.bigint :positianable_id, null: false
      t.string :positianable_type, null: false
      t.references :chart, null: false, foreign_key: true
      t.timestamps
    end

    add_index :chart_positions, [:positianable_id, :positianable_type]
    add_reference :charts, :chart_positions, foreign_key: true
  end
end
