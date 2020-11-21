# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Generalplaylist do
  let(:artist_1) { FactoryBot.create :artist }
  let(:song_1) { FactoryBot.create :song, artists: [artist_1] }
  let(:artist_2) { FactoryBot.create :artist }
  let(:song_2) { FactoryBot.create :song, artists: [artist_2] }
  let(:artist_3) { FactoryBot.create :artist, name: 'Robin Schulz' }
  let(:song_3) { FactoryBot.create :song, artists: [artist_3] }
  let(:artist_4) { FactoryBot.create :artist, name: 'Erika Sirola' }
  let(:song_4) { FactoryBot.create :song, artists: [artist_4] }
  let(:radio_station) { FactoryBot.create :radiostation }
  let(:playlist_1) { FactoryBot.create :generalplaylist, :filled, song: song_1, radiostation: radio_station }
  let(:playlist_2) { FactoryBot.create :generalplaylist, :filled, song: song_2, radiostation: radio_station }
  let(:playlist_3) { FactoryBot.create :generalplaylist, :filled, song: song_2, radiostation: radio_station }

  let(:song_in_your_eyes_weekend) { FactoryBot.create :song, title: 'In Your Eyes', artists: [artist_the_weeknd] }
  let(:artist_the_weeknd) { FactoryBot.create :artist, name: 'The Weeknd' }
  let(:song_in_your_eyes_robin_schulz) { FactoryBot.create :song, title: 'In Your Eyes', artists: [artist_robin_schulz, artist_alida] }
  let(:artist_robin_schulz) { FactoryBot.create :artist, name: 'Robin Schulz' }
  let(:artist_alida) { FactoryBot.create :artist, name: 'Alida' }

  describe '#npo_api_processor' do
    context 'given an address and radiostation' do
      let(:radio_1) { FactoryBot.create(:radio_1) }
      it 'creates a new playlist item' do
        track_data = Generalplaylist.npo_api_processor(radio_1)

        if track_data.is_a?(Array)
          expect(track_data).to be_an_instance_of(Array)
          expect(track_data.count).to eq 3
        else
          expect(track_data).to eq false
        end
      end
    end
  end

  describe '#talpa_api_processor' do
    context 'given an address and radiostation' do
      let(:sky_radio) { FactoryBot.create(:sky_radio) }
      it 'creates an new playlist item' do
        track_data = Generalplaylist.talpa_api_processor(sky_radio)

        if track_data.is_a?(Array)
          expect(track_data).to be_an_instance_of(Array)
          expect(track_data.count).to eq 3
        else
          expect(track_data).to eq false
        end
      end
    end
  end

  describe '#radio_1_check' do
    let!(:radio_1) { FactoryBot.create(:radio_1) }
    it 'creates a new playlist item' do
      expect {
        Generalplaylist.radio_1_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#radio_2_check' do
    let!(:radio_2) { FactoryBot.create(:radio_2) }
    it 'creates a new playlist item' do
      allow(Generalplaylist).to receive(:npo_api_processor).and_return(['Goldkimono', 'To Tomorrow', '20:13'])
      expect {
        Generalplaylist.radio_2_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#radio_3fm_check' do
    let!(:radio_3_fm) { FactoryBot.create(:radio_3_fm) }
    it 'creates a new playlist item' do
      allow(Generalplaylist).to receive(:npo_api_processor).and_return(['Haim', 'The Steps', '19:16'])
      expect {
        Generalplaylist.radio_3fm_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#radio_5_check' do
    let!(:radio_5) { FactoryBot.create(:radio_5) }
    it 'creates a new playlist item' do
      allow(Generalplaylist).to receive(:npo_api_processor).and_return(['Fleetwood Mac', 'Everywhere', '19:05'])
      expect {
        Generalplaylist.radio_5_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#sky_radio_check' do
    let!(:sky_radio) { FactoryBot.create(:sky_radio) }
    it 'creates a new playlist item' do
      allow(Generalplaylist).to receive(:talpa_api_processor).and_return(['Billy Ocean', 'When The Going Gets Tough', '13:17'])
      expect {
        Generalplaylist.sky_radio_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#radio_veronica_check' do
    let!(:radio_veronica) { FactoryBot.create(:radio_veronica) }
    it 'creates a new playlist item' do
      allow(Generalplaylist).to receive(:talpa_api_processor).and_return(['Earth, Wind & Fire', "Let's Groove", '20:16'])
      expect {
        Generalplaylist.radio_veronica_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#radio_538_check' do
    let!(:radio_538) { FactoryBot.create(:radio_538) }
    before do
      allow(Generalplaylist).to receive(:talpa_api_processor).and_return(['Robin Schulz, Erika Sirola', 'Speechless', '19:20'])
    end
    it 'creates a new playlist item' do
      expect {
        Generalplaylist.radio_538_check
      }.to change(Generalplaylist, :count).by(1)
    end
    context 'with two artist' do
      it 'sets both artists to the song' do
        Generalplaylist.radio_538_check

        song = Song.find_by(title: 'Speechless (feat. Erika Sirola)')
        expect(song.artists.map(&:name)).to contain_exactly 'Robin Schulz', 'Erika Sirola'
      end
    end
  end

  describe '#radio_10_check' do
    let!(:radio_10) { FactoryBot.create(:radio_10) }
    it 'creates a new playlist item' do
      allow(Generalplaylist).to receive(:talpa_api_processor).and_return(['The Farm', 'All Together Now', '13:39'])
      expect {
        Generalplaylist.radio_10_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#q_music_check' do
    let!(:qmusic) { FactoryBot.create(:qmusic) }
    it 'creates a new playlist item' do
      expect {
        Generalplaylist.q_music_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#sublime_fm_check' do
    let!(:sublime_fm) { FactoryBot.create(:sublime_fm) }
    it 'creates a new playlist item' do
      expect {
        Generalplaylist.sublime_fm_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#grootnieuws_radio_check' do
    let!(:groot_nieuws_radio) { FactoryBot.create(:groot_nieuws_radio) }
    it 'creates a new playlist item' do
      expect {
        Generalplaylist.grootnieuws_radio_check
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#illegal_word_in_title' do
    context 'a title with more then 4 digits' do
      it 'returns false' do
        expect(Generalplaylist.illegal_word_in_title('test 1234')).to eq true
      end
    end

    context 'a title with a forward slash' do
      it 'returns false' do
        expect(Generalplaylist.illegal_word_in_title('test / go ')).to eq true
      end
    end

    context 'a title with 2 single qoutes' do
      it 'returns false' do
        expect(Generalplaylist.illegal_word_in_title("test''s")).to eq true
      end
    end

    context 'a titlle that has reklame or reclame' do
      it 'returns false' do
        expect(Generalplaylist.illegal_word_in_title('test reclame')).to eq true
      end
    end

    context 'a title that has more then two dots' do
      it 'returns false' do
        expect(Generalplaylist.illegal_word_in_title('test..test')).to eq true
      end
    end

    context 'when the title contains "nieuws"' do
      it 'returns false' do
        expect(Generalplaylist.illegal_word_in_title('ANP NIEUWS')).to eq true
      end
    end

    context 'when the title contains "pingel"' do
      it 'returns false' do
        expect(Generalplaylist.illegal_word_in_title('Kerst pingel')).to eq true
      end
    end

    context 'any other title' do
      it 'returns true' do
        expect(Generalplaylist.illegal_word_in_title('Liquid Spirit')).to eq false
      end
    end
  end

  describe '#search' do
    before do
      playlist_1
      playlist_2
      playlist_3
    end
    context 'with search term params' do
      it 'returns the playlists artist name or song title that matches the search terms' do
        expected = [playlist_1]

        expect(Generalplaylist.search({ search_term: song_1.title })).to eq expected
      end
    end

    context 'with radiostations params' do
      it 'returns the playlist played on the radiostation' do
        expect(Generalplaylist.search({ radiostation_id: radio_station.id })).to include playlist_2, playlist_3
      end
    end

    context 'with no params' do
      it 'returns all the playlists' do
        expect(Generalplaylist.search({})).to include playlist_1, playlist_2, playlist_3
      end
    end
  end

  describe '#today_unique_playlist_item' do
    before { playlist_1 }
    context 'with an already playlist existing item' do
      it 'fails validation' do
        new_playlist_item = Generalplaylist.new(broadcast_timestamp: playlist_1.broadcast_timestamp, song: playlist_1.song, radiostation: playlist_1.radiostation)

        expect(new_playlist_item.valid?).to eq false
      end
    end

    context 'with a unique playlist item' do
      it 'does not fail validation' do
        new_playlist_item = FactoryBot.build :generalplaylist, :filled

        expect(new_playlist_item.valid?).to eq true
      end
    end
  end

  describe '#find_or_create_artist' do
    context 'with multiple name' do
      it 'returns the artists and not a karaoke version' do
        result = Generalplaylist.find_or_create_artist('Martin Garrix & Clinton Kane', 'Drown')

        expect(result.map(&:name)).to contain_exactly 'Martin Garrix', 'Clinton Kane'
      end
    end
  end

  describe '#song_check' do
    before { song_in_your_eyes_robin_schulz }
    context 'with a song present with the same name but different artist(s)' do
      it 'creates a new artist' do
        song = Generalplaylist.song_check([song_in_your_eyes_robin_schulz], [artist_the_weeknd], 'In Your Eyes')

        expect(song.artists).to contain_exactly artist_the_weeknd
      end
    end

    context 'when the song is present with the same artist(s)' do
      it 'doesnt create a new artist' do
        song = Generalplaylist.song_check([song_in_your_eyes_weekend], [artist_the_weeknd], 'In Your Eyes')

        expect(song.artists).to contain_exactly artist_the_weeknd
      end
    end

    context 'when the title is differently capitalized' do
      it 'it doesnt create a new song but finds the existing one' do
        song = nil
        expect {
          song = Generalplaylist.song_check([song_in_your_eyes_weekend], [artist_the_weeknd], 'In your eyes')
        }.to change(Generalplaylist, :count).by(0)

        expect(song.title).to eq 'In Your Eyes'
      end
    end
  end
end
