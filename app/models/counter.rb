class Counter < ApplicationRecord
  belongs_to :song

  validates :song, presence: true
end
