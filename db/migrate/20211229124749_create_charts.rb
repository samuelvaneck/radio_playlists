class CreateCharts < ActiveRecord::Migration[6.1]
  def change
    create_table :charts do |t|
      t.datetime :date
      t.jsonb :chart, default: []
      t.string :type

      t.timestamps
    end
  end
end
