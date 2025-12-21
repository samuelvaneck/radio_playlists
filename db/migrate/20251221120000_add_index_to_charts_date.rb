# frozen_string_literal: true

class AddIndexToChartsDate < ActiveRecord::Migration[8.0]
  def change
    add_index :charts, :date
  end
end
