class CreateArtistsGeneralplaylists < ActiveRecord::Migration
  def change
    create_table :artists_generalplaylists do |t|
      t.references :artist, index: true, foreign_key: true
      t.references :generalplaylist, index: true, foreign_key: true
    end
  end
end
