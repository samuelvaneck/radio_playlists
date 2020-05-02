# frozen_string_literal: true

class Artist < ActiveRecord::Base
  has_many :generalplaylists
  has_many :songs
  has_many :radiostations, through: :generalplaylists
end
