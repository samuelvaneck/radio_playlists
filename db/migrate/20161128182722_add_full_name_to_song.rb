class AddFullNameToSong < ActiveRecord::Migration
  def change
    add_column :songs, :fullname, :text
  end
end
