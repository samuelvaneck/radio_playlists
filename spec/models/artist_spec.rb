# # frozen_string_literal: true

require 'rails_helper'

RSpec.describe Artist do
  let(:artist_1) { FactoryBot.create :artist }
  let(:song_1) { FactoryBot.create :song, artists: [artist_1] }
  let(:artist_2) { FactoryBot.create :artist }
  let(:song_2) { FactoryBot.create :song, artists: [artist_2] }
  let(:artist_3) { FactoryBot.create :artist }
  let(:song_3) { FactoryBot.create :song, artists: [artist_3] }
  let(:radiostation) { FactoryBot.create :radiostation }
  let(:playlist_1) { FactoryBot.create :generalplaylist, :filled, song: song_1 }
  let(:playlist_2) { FactoryBot.create :generalplaylist, :filled, song: song_2, radiostation: radiostation }
  let(:playlist_3) { FactoryBot.create :generalplaylist, :filled, song: song_3, radiostation: radiostation }
  let(:playlist_4) { FactoryBot.create :generalplaylist, :filled, song: song_3, radiostation: radiostation }

  before do
    playlist_1
    playlist_2
    playlist_3
    playlist_4
  end

  describe '#search' do
    context 'with search term params present' do
      it 'only returns the artists matching the search term' do
        results = Artist.search({ search_term: artist_1.name })

        expect(results).to include artist_1
      end
    end

    context 'with radiostation_id params present' do
      it 'only returns the artists played on the radiostation' do
        results = Artist.search({ radiostation_id: radiostation.id })

        expect(results).to include artist_2, artist_3
      end
    end
  end

  describe '#group_and_count' do
    it 'groups and counts the artist' do
      results = Artist.group_and_count(Artist.joins(:generalplaylists).all)

      expect(results).to include [artist_3.id, 2], [artist_2.id, 1], [artist_1.id, 1]
    end
  end

  describe '#cleanup' do
    context 'if the artist has no songs' do
      let!(:artist_no_songs) { FactoryBot.create :artist }
      it 'destorys the artist' do
        expect {
          artist_no_songs.cleanup
        }.to change(Artist, :count).by(-1)
      end
    end

    context 'if the artist has songs' do
      it 'does not destroy the artist' do
        expect {
          artist_1.cleanup
        }.to change(Artist, :count).by(0)
      end
    end
  end
end
