class CreateGeneralplaylistsRadiostations < ActiveRecord::Migration
  def change
    create_table :generalplaylists_radiostations do |t|
      t.references :generalplaylist, index: true, foreign_key: true
      t.references :radiostation, index: true, foreign_key: true
    end
  end
end
