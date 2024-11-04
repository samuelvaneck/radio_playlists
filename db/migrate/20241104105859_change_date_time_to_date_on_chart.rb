class ChangeDateTimeToDateOnChart < ActiveRecord::Migration[7.2]
  def up
    change_column :charts, :date, :date
    remove_column :charts, :chart
  end

  def down
    change_column :charts, :date, :datetime
    add_column :charts, :chart, :jsonb
  end
end
