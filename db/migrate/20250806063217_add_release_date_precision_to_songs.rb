class AddReleaseDatePrecisionToSongs < ActiveRecord::Migration[8.0]
  def change
    add_column :songs, :release_date_precision, :string

    Song.where.not(release_date: nil).update_all(release_date_precision: 'date')
  end
end
