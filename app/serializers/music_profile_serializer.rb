# frozen_string_literal: true

# == Schema Information
#
# Table name: music_profiles
#
#  id               :bigint           not null, primary key
#  acousticness     :decimal(5, 4)
#  danceability     :decimal(5, 4)
#  energy           :decimal(5, 4)
#  instrumentalness :decimal(5, 4)
#  liveness         :decimal(5, 4)
#  speechiness      :decimal(5, 4)
#  tempo            :decimal(6, 2)
#  valence          :decimal(5, 4)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  song_id          :bigint           not null
#
# Indexes
#
#  index_music_profiles_on_song_id  (song_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (song_id => songs.id)
#
class MusicProfileSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :danceability,
             :energy,
             :speechiness,
             :acousticness,
             :instrumentalness,
             :liveness,
             :valence,
             :tempo

  class << self
    def attribute_descriptions
      MusicProfile::ATTRIBUTE_DESCRIPTIONS
    end

    def serializable_hash_with_descriptions(profiles, options = {})
      hash = new(profiles, options).serializable_hash
      hash[:meta] = { attribute_descriptions: attribute_descriptions }
      hash
    end
  end
end
