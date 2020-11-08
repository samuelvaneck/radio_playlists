class Radiostation < ActiveRecord::Base
  has_many :generalplaylists
  has_many :songs, through: :generalplaylists
  has_many :artists, through: :songs

  def status
    last_created = Generalplaylist.where(radiostation: self).order(created_at: :desc).first
    {
      last_created_at: last_created.created_at,
      track_info: "#{last_created.song.artists.map(&:name).join(' - ')} - #{last_created.song.title}",
      status: last_created.created_at > 3.hour.ago ? 'OK' : 'Warning'
    }
  end
end
