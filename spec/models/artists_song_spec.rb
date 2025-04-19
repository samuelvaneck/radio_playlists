# frozen_string_literal: true

# == Schema Information
#
# Table name: artists_songs
#
#  song_id   :bigint           not null
#  artist_id :bigint           not null
#
describe ArtistsSong, type: :model do
  let(:artists_song) { create(:artists_song) }

  describe 'validations' do
    context 'when creating a new record with no duplication artist song' do
      it 'save a new ArtistsSong in the database' do
        expect do
          artists_song
        end.to change(described_class, :count).by(2)
      end
    end

    context 'when trying to create a duplicate record' do
      let(:artist) { artists_song.artist }
      let(:song) { artists_song.song }
      let(:invalid_record) { build(:artists_song, artist:, song:) }

      before { artists_song }

      it 'does not save the record in the database' do
        expect do
          invalid_record.save
        end.to change(described_class, :count).by(0)
      end

      it 'does not validate the new record' do
        expect(invalid_record).not_to be_valid
      end
    end
  end
end
