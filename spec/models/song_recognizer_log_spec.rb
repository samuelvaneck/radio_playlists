# == Schema Information
#
# Table name: song_recognizer_logs
#
#  id                       :bigint           not null, primary key
#  radio_station_id         :bigint           not null
#  song_match               :integer
#  recognizer_song_fullname :string
#  api_song_fullname        :string
#  result                   :jsonb
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
require 'rails_helper'

RSpec.describe SongRecognizerLog, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
