class AddStatusToAirPlays < ActiveRecord::Migration[8.1]
  def change
    # Default 1 (confirmed) for existing records, new records will be draft (0) by default in the model
    add_column :air_plays, :status, :integer, default: 1, null: false
    add_index :air_plays, :status
  end
end
