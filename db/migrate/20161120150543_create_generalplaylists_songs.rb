class CreateGeneralplaylistsSongs < ActiveRecord::Migration
  def change
    create_table :generalplaylists_songs do |t|
      t.references :generalplaylist, index: true, foreign_key: true
      t.references :song, index: true, foreign_key: true
    end
  end
end
