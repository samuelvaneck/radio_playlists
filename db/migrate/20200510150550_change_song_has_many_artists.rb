# frozen_string_literal: true

class ChangeSongHasManyArtists < ActiveRecord::Migration[6.0]
  def up
    create_join_table :songs, :artists do |t|
      t.index :song_id
      t.index :artist_id
    end

    Song.class_eval do
      belongs_to :artist, class_name: 'Artist', foreign_key: 'artist_id'
    end

    Song.all.each do |song|
      track = RSpotify::Track.search(song.fullname || "#{song.artist&.name} #{song.title}").sort_by(&:popularity).reverse.first
      next if track.blank?

      artist_names = track&.artists&.map(&:name)
      next if artist_names.blank?

      artist_names.each do |name|
        artist = Artist.find_or_create_by(name: name)
        next if song.artists.include? artist

        song.artists << artist
      end
      sleep 1 # fix to many requests error during migration
    end

    # remove reference from song and generalplaylists
    remove_reference :songs, :artist, index: true, foreign_key: true
    remove_reference :generalplaylists, :artist, index: true, foreign_key: true
  end

  def down
    add_references :songs, :artist, index: true, foreign_key: true

    Song.all.each do |song|
      songs.artist = song.artists.join(' ft ')
    end

    drop_join_table :songs, :artists, table_name: artists_songs
  end
end
