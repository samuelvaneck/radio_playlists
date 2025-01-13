# frozen_string_literal: true

class AddIdOnYouTubeToSongs < ActiveRecord::Migration[7.2]
  def change
    add_column :songs, :id_on_youtube, :string
  end
end
