class RenameFullnameToSearchTextOnSongs < ActiveRecord::Migration[8.0]
  def change
    rename_column :songs, :fullname, :search_text
  end
end
