# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Radiostation do
  let(:radio_station) { FactoryBot.create :radiostation }
  let(:playlist_4_hours_ago) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station, created_at: 4.hours.ago }
  let(:playlist_1_minute_ago) { FactoryBot.create :generalplaylist, :filled, radiostation: radio_station, created_at: 1.minute.ago }

  let(:song_in_your_eyes_robin_schulz) { FactoryBot.create :song, title: 'In Your Eyes', artists: [artist_robin_schulz, artist_alida] }
  let(:song_in_your_eyes_weekend) { FactoryBot.create :song, title: 'In Your Eyes', artists: [artist_the_weeknd] }
  let(:artist_the_weeknd) { FactoryBot.create :artist, name: 'The Weeknd' }
  let(:artist_robin_schulz) { FactoryBot.create :artist, name: 'Robin Schulz' }
  let(:artist_alida) { FactoryBot.create :artist, name: 'Alida' }


  describe '#validations' do
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:processor) }
  end

  describe '#status' do
    let(:status) { radio_station.status }
    context 'with a last playlist created 2 hours ago' do
      before { playlist_4_hours_ago }
      it 'has status warning' do
        expect(status).to eq 'warning'
      end
    end

    context 'with a last playlist created 1 minute ago' do
      before { playlist_1_minute_ago }
      it 'has status OK' do
        expect(status).to eq 'ok'
      end
    end
  end

  describe '#mail_data' do
    let(:mail_data) { radio_station.mail_data }
    before do
      playlist_4_hours_ago
      playlist_1_minute_ago
    end
    it 'has a key track info' do
      expect(mail_data[:track_info]).to eq "#{playlist_1_minute_ago.song.artists.map(&:name).join(' & ')} - #{playlist_1_minute_ago.song.title}"
    end

    it 'has a key last_create_at' do
      expect(mail_data[:last_created_at].strftime('%H:%M:%S')).to eq playlist_1_minute_ago.created_at.strftime('%H:%M:%S')
    end

    it 'has a key total_created' do
      expect(mail_data[:total_created]).to eq 2
    end
  end

  describe '#last_created' do
    it 'returns the last created item' do
      playlist_4_hours_ago
      playlist_1_minute_ago

      expect(radio_station.last_created).to eq playlist_1_minute_ago
    end
  end

  describe '#todays_added_items' do
    it 'returns all todays added items from the radiostation' do
      playlist_4_hours_ago
      playlist_1_minute_ago

      expect(radio_station.todays_added_items).to include playlist_4_hours_ago, playlist_1_minute_ago
    end
  end

  describe '#npo_api_processor' do
    context 'given an address and radiostation' do
      let(:radio_1) { FactoryBot.create(:radio_1) }
      it 'creates a new playlist item' do
        track_data = radio_1.npo_api_processor

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
        track_data = sky_radio.talpa_api_processor

        if track_data.is_a?(Array)
          expect(track_data).to be_an_instance_of(Array)
          expect(track_data.count).to eq 3
        else
          expect(track_data).to eq false
        end
      end
    end
  end

  describe '#scraper' do
    context 'if radio_station is Sublime FM' do
      let(:sublime_fm) { FactoryBot.create(:sublime_fm) }
      it 'returns an artist_name, title and time' do
        track_data = sublime_fm.scraper

        expect(track_data.count).to eq 3
      end
    end

    context 'if radio_station is Groot Nieuws RAdio' do
      let(:groot_nieuws_radio) { FactoryBot.create(:groot_nieuws_radio) }
      it 'returns an artist_name, titile and time' do
        track_data = groot_nieuws_radio.scraper

        expect(track_data.count).to eq 3
      end
    end
  end

  describe '#radio_1_check' do
    let!(:radio_1) { FactoryBot.create(:radio_1) }
    it 'creates a new playlist item' do
      expect {
        radio_1.import_song
      }.to change(Generalplaylist, :count).by(1)
    end

    it 'does not double import' do
      radio_1.import_song

      expect {
        radio_1.import_song
      }.to change(Generalplaylist, :count).by(0)
    end
  end

  describe '#radio_2_check' do
    let!(:radio_2) { FactoryBot.create(:radio_2) }
    it 'creates a new playlist item' do
      allow_any_instance_of(Radiostation).to receive(:npo_api_processor).and_return(['Goldkimono', 'To Tomorrow', '20:13'])
      expect {
        radio_2.import_song
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#radio_3fm_check' do
    let!(:radio_3_fm) { FactoryBot.create(:radio_3_fm) }
    it 'creates a new playlist item' do
      allow_any_instance_of(Radiostation).to receive(:npo_api_processor).and_return(['Haim', 'The Steps', '19:16'])
      expect {
        radio_3_fm.import_song
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#radio_5_check' do
    let!(:radio_5) { FactoryBot.create(:radio_5) }
    it 'creates a new playlist item' do
      allow_any_instance_of(Radiostation).to receive(:npo_api_processor).and_return(['Fleetwood Mac', 'Everywhere', '19:05'])
      expect {
        radio_5.import_song
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#sky_radio_check' do
    let!(:sky_radio) { FactoryBot.create(:sky_radio) }
    it 'creates a new playlist item' do
      allow_any_instance_of(Radiostation).to receive(:talpa_api_processor).and_return(['Billy Ocean', 'When The Going Gets Tough', '13:17'])
      expect {
        sky_radio.import_song
      }.to change(Generalplaylist, :count).by(1)
    end

    it 'does not double import' do
      sky_radio.import_song

      expect {
        sky_radio.import_song
      }.to change(Generalplaylist, :count).by(0)
    end
  end

  describe '#radio_veronica_check' do
    let!(:radio_veronica) { FactoryBot.create(:radio_veronica) }
    it 'creates a new playlist item' do
      allow_any_instance_of(Radiostation).to receive(:talpa_api_processor).and_return(['Earth, Wind & Fire', "Let's Groove", '20:16'])
      expect {
        radio_veronica.import_song
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#radio_538_check' do
    let!(:radio_538) { FactoryBot.create(:radio_538) }
    before do
      allow_any_instance_of(Radiostation).to receive(:talpa_api_processor).and_return(['Robin Schulz, Erika Sirola', 'Speechless', '19:20'])
    end
    it 'creates a new playlist item' do
      expect {
        radio_538.import_song
      }.to change(Generalplaylist, :count).by(1)
    end
    context 'with two artist' do
      it 'sets both artists to the song' do
        radio_538.import_song

        song = Song.find_by(title: 'Speechless (feat. Erika Sirola)')
        expect(song.artists.map(&:name)).to contain_exactly 'Robin Schulz', 'Erika Sirola'
      end
    end
  end

  describe '#radio_10_check' do
    let!(:radio_10) { FactoryBot.create(:radio_10) }
    it 'creates a new playlist item' do
      allow_any_instance_of(Radiostation).to receive(:talpa_api_processor).and_return(['The Farm', 'All Together Now', '13:39'])
      expect {
        radio_10.import_song
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#q_music_check' do
    let!(:qmusic) { FactoryBot.create(:qmusic) }
    it 'creates a new playlist item' do
      expect {
        qmusic.import_song
      }.to change(Generalplaylist, :count).by(1)
    end

    it 'does not double import' do
      qmusic.import_song

      expect {
        qmusic.import_song
      }.to change(Generalplaylist, :count).by(0)
    end
  end

  describe '#sublime_fm_check' do
    let!(:sublime_fm) { FactoryBot.create(:sublime_fm) }
    it 'creates a new playlist item' do
      expect {
        sublime_fm.import_song
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#grootnieuws_radio_check' do
    let!(:groot_nieuws_radio) { FactoryBot.create(:groot_nieuws_radio) }
    it 'creates a new playlist item' do
      expect {
        groot_nieuws_radio.import_song
      }.to change(Generalplaylist, :count).by(1)
    end
  end

  describe '#illegal_word_in_title' do
    context 'a title with more then 4 digits' do
      it 'returns false' do
        expect(Radiostation.new.illegal_word_in_title('test 1234')).to eq true
      end
    end

    context 'a title with a forward slash' do
      it 'returns false' do
        expect(Radiostation.new.illegal_word_in_title('test / go ')).to eq true
      end
    end

    context 'a title with 2 single qoutes' do
      it 'returns false' do
        expect(Radiostation.new.illegal_word_in_title("test''s")).to eq true
      end
    end

    context 'a titlle that has reklame or reclame' do
      it 'returns false' do
        expect(Radiostation.new.illegal_word_in_title('test reclame')).to eq true
      end
    end

    context 'a title that has more then two dots' do
      it 'returns false' do
        expect(Radiostation.new.illegal_word_in_title('test..test')).to eq true
      end
    end

    context 'when the title contains "nieuws"' do
      it 'returns false' do
        expect(Radiostation.new.illegal_word_in_title('ANP NIEUWS')).to eq true
      end
    end

    context 'when the title contains "pingel"' do
      it 'returns false' do
        expect(Radiostation.new.illegal_word_in_title('Kerst pingel')).to eq true
      end
    end

    context 'any other title' do
      it 'returns true' do
        expect(Radiostation.new.illegal_word_in_title('Liquid Spirit')).to eq false
      end
    end
  end

  describe '#find_or_create_artist' do
    context 'with multiple name' do
      it 'returns the artists and not a karaoke version' do
        result = Radiostation.new.find_or_create_artist('Martin Garrix & Clinton Kane', 'Drown')

        expect(result.map(&:name)).to contain_exactly 'Martin Garrix', 'Clinton Kane'
      end
    end
  end

  describe '#song_check' do
    before { song_in_your_eyes_robin_schulz }
    context 'with a song present with the same name but different artist(s)' do
      it 'creates a new artist' do
        song = Radiostation.new.song_check([song_in_your_eyes_robin_schulz], [artist_the_weeknd], 'In Your Eyes')

        expect(song.artists).to contain_exactly artist_the_weeknd
      end
    end

    context 'when the song is present with the same artist(s)' do
      it 'doesnt create a new artist' do
        song = Radiostation.new.song_check([song_in_your_eyes_weekend], [artist_the_weeknd], 'In Your Eyes')

        expect(song.artists).to contain_exactly artist_the_weeknd
      end
    end

    context 'when the title is differently capitalized' do
      it 'it doesnt create a new song but finds the existing one' do
        song = nil
        expect {
          song = Radiostation.new.song_check([song_in_your_eyes_weekend], [artist_the_weeknd], 'In your eyes')
        }.to change(Generalplaylist, :count).by(0)

        expect(song.title).to eq 'In Your Eyes'
      end
    end
  end
end
