class AddHitPotentialScoreToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :hit_potential_score, :decimal, precision: 5, scale: 2
  end
end
