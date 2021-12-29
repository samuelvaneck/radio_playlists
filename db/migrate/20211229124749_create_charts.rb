# frozen_string_literal: true

class CreateCharts < ActiveRecord::Migration[6.1]
  def change
    create_table :charts do |t|
      t.datetime :date
      t.jsonb :chart, default: []
      t.string :chart_type

      t.timestamps
    end
  end
end
