class AddFullNameToSong < ActiveRecord::Migration[5.1]
  def change
    add_column :songs, :fullname, :text
  end
end
