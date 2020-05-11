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

    old_artists = []
    Song.all.each do |song|
      regex = Regexp.new('\b(feat.|feat|ft.|ft|vs.|vs|versus|,|and|met)\s|(\b;|&)', Regexp::IGNORECASE)
      next unless regex.match?(song.artist.name)

      old_artists << song.artist
      artist_array = song.artist.name.split(regex).map(&:strip)
      artist_array.each do |name|
        new_artist = Artist.find_or_create_by(name: name)
        song.artists << new_artist
      end
    end

    # remove reference from song and generalplaylists
    remove_reference :songs, :artist, index: true, foreign_key: true
    remove_reference :generalplaylists, :artist, index: true, foreign_key: true

    old_artists.each(&:delete)
  end

  def down
    add_references :songs, :artist, index: true, foreign_key: true

    Song.all.each do |song|
      songs.artist = song.artists.join(' ft ')
    end

    drop_join_table :songs, :artists, table_name: artists_songs
  end
end
