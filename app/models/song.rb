# frozen_string_literal: true

class Song < ActiveRecord::Base
  has_many :generalplaylists
  has_many :counters
  has_many :radiostations, through: :generalplaylists
  belongs_to :artist

  validates :artist, presence: true

  def self.search_title(title)
    where('title ILIKE ?', "%#{title}%")
  end
end
