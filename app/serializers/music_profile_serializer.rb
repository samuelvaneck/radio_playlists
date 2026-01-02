# frozen_string_literal: true

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
