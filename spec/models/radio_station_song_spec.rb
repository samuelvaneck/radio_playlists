# == Schema Information
#
# Table name: radio_station_songs
#
#  id                   :bigint           not null, primary key
#  song_id              :bigint           not null
#  radio_station_id     :bigint           not null
#  first_broadcasted_at :datetime
#
require 'rails_helper'

RSpec.describe RadioStationSong, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:song) }
    it { is_expected.to belong_to(:radio_station) }
  end
end
