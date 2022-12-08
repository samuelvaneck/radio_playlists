class AddStreamUrlToRadioStation < ActiveRecord::Migration[7.0]
  def change
    add_column :radio_stations, :stream_url, :string
  end
end
