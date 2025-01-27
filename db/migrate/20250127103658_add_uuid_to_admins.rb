class AddUuidToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :uuid, :string, null: false, default: ''
    add_index :admins, :uuid, unique: true
  end
end
