# frozen_string_literal: true

# == Schema Information
#
# Table name: song_recognizer_logs
#
#  id                       :bigint           not null, primary key
#  radio_station_id         :bigint           not null
#  song_match               :integer
#  recognizer_song_fullname :string
#  api_song_fullname        :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class SongRecognizerLog < ApplicationRecord
  belongs_to :radio_station
end
