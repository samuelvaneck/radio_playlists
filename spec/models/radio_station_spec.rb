# frozen_string_literal: true

# == Schema Information
#
# Table name: radio_stations
#
#  id                      :bigint           not null, primary key
#  name                    :string
#  genre                   :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  url                     :text
#  processor               :string
#  stream_url              :string
#  slug                    :string
#  country_code            :string
#  last_added_playlist_ids :jsonb
#
describe RadioStation, :use_vcr, :with_valid_token do
  let(:radio_station) { create :radio_station }
  let(:playlist_4_hours_ago) { create :playlist, radio_station:, created_at: 4.hours.ago }
  let(:playlist_1_minute_ago) { create :playlist, radio_station:, created_at: 1.minute.ago }

  def processor_return_object(artist_name, title, time)
    {
      artist_name:,
      title:,
      broadcast_timestamp: Time.find_zone('Amsterdam').parse(time),
      spotify_url: nil
    }
  end

  describe '#last_added_playlists' do
    before do
      radio_station.update(last_added_playlist_ids: [playlist_4_hours_ago.id, playlist_1_minute_ago.id])
    end

    it 'returns the last created item' do
      expect(radio_station.last_added_playlists).to contain_exactly(playlist_4_hours_ago, playlist_1_minute_ago)
    end
  end

  describe '#today_added_items' do
    it 'returns all todays added items from the radio station' do
      playlist_4_hours_ago
      playlist_1_minute_ago

      expect(radio_station.today_added_items).to include playlist_4_hours_ago, playlist_1_minute_ago
    end
  end

  describe '#npo_api_processor' do
    let(:radio_1) { described_class.find_by(name: 'Radio 1') || create(:radio_1) }

    context 'given an address and radio station' do
      let(:track_data) { "TrackScraper::#{radio_1.processor&.camelcase}".constantize.new(radio_1).last_played_song }

      it 'creates a new playlist item' do
        expect(track_data).to be true
      end
    end
  end

  describe '#talpa_api_processor' do
    let(:sky_radio) { described_class.find_by(name: 'Sky Radio') || create(:sky_radio) }

    context 'given an address and radio station' do
      let(:track_data) { "TrackScraper::#{sky_radio.processor&.camelcase}".constantize.new(sky_radio).last_played_song }

      it 'creates an new playlist item' do
        expect(track_data).to be true
      end
    end
  end

  describe '#scraper' do
    let(:sublime_fm) { create(:sublime_fm) }
    let(:groot_nieuws_radio) { described_class.find_by(name: 'Groot Nieuws Radio') || create(:groot_nieuws_radio) }

    xcontext 'if radio_station is Sublime FM' do
      let(:track_data) { "TrackScraper::#{sublime_fm.processor&.camelcase}".constantize.new(sublime_fm).last_played_song }

      it 'returns an artist_name, title and time' do
        expect(track_data).to be true
      end
    end

    xcontext 'if radio_station is Groot Nieuws Radio' do
      let(:track_data) { "TrackScraper::#{groot_nieuws_radio.processor&.camelcase}".constantize.new(groot_nieuws_radio).last_played_song }

      it 'returns an artist_name, titile and time' do
        expect(track_data).to be true
      end
    end
  end

  xdescribe '#radio_1_check' do
    let!(:radio_1) { create(:radio_1) }

    context 'when importing a song' do
      it 'creates a new playlist item' do
        expect do
          radio_1.import_song
        end.to change(Playlist, :count).by(1)
      end

      it 'does not double import' do
        radio_1.import_song
        expect do
          radio_1.import_song
        end.not_to change(Playlist, :count)
      end
    end
  end

  xdescribe '#radio_2_check' do
    let!(:radio_two) { create(:npo_radio_two) }

    context 'when importing a song' do
      it 'creates a new playlist item' do
        expect do
          radio_two.import_song
        end.to change(Playlist, :count).by(1)
      end
    end
  end

  xdescribe '#radio_3fm_check' do
    let!(:radio_3_fm) { create(:radio_3_fm) }

    context 'when importing a song' do
      it 'creates a new playlist item' do
        expect do
          radio_3_fm.import_song
        end.to change(Playlist, :count).by(1)
      end
    end
  end

  xdescribe '#radio_5_check' do
    let!(:radio_5) { create(:radio_5) }

    context 'when importing song' do
      it 'creates a new playlist item' do
        expect do
          radio_5.import_song
        end.to change(Playlist, :count).by(1)
      end
    end
  end

  xdescribe '#sky_radio_check' do
    let!(:sky_radio) { create(:sky_radio) }

    before do
      allow_any_instance_of(Spotify).to receive(:track).and_return([])
    end

    context 'when importing song' do
      it 'creates a new playlist item' do
        expect do
          sky_radio.import_song
        end.to change(Playlist, :count).by(1)
      end

      it 'does not double import' do
        sky_radio.import_song

        expect do
          sky_radio.import_song
        end.not_to change(Playlist, :count)
      end
    end
  end

  xdescribe '#radio_veronica_check' do
    let!(:radio_veronica) { create(:radio_veronica) }

    before do
      allow_any_instance_of(Spotify).to receive(:track).and_return([])
    end

    context 'when importing song' do
      it 'creates a new playlist item' do
        expect do
          radio_veronica.import_song
        end.to change(Playlist, :count).by(1)
      end
    end
  end

  xdescribe '#radio_538_check' do
    let(:radio_538) { create(:radio_538) }

    before do
      allow_any_instance_of(Spotify).to receive(:track).and_return([])
    end

    context 'when importing song' do
      it 'creates a new playlist item' do
        expect do
          radio_538.import_song
        end.to change(Playlist, :count).by(1)
      end
    end
  end

  xdescribe '#radio_10_check' do
    let!(:radio_10) { create(:radio_10) }

    before do
      allow_any_instance_of(Spotify).to receive(:track).and_return([])
    end

    context 'when importing song' do
      it 'creates a new playlist item' do
        expect do
          radio_10.import_song
        end.to change(Playlist, :count).by(1)
      end
    end
  end

  xdescribe '#q_music_check' do
    let!(:qmusic) { create(:qmusic) }

    context 'when importing song' do
      it 'creates a new playlist item' do
        expect do
          qmusic.import_song
        end.to change(Playlist, :count).by(1)
      end

      it 'does not double import' do
        qmusic.import_song

        expect do
          qmusic.import_song
        end.not_to change(Playlist, :count)
      end
    end
  end

  xdescribe '#sublime_fm_check' do
    let!(:sublime_fm) { create(:sublime_fm) }

    context 'when importing song' do
      it 'creates a new playlist item' do
        expect do
          sublime_fm.import_song
        end.to change(Playlist, :count).by(1)
      end
    end
  end

  xdescribe '#grootnieuws_radio_check' do
    let!(:groot_nieuws_radio) { create(:groot_nieuws_radio) }

    context 'when importing song' do
      it 'creates a new playlist item' do
        expect do
          groot_nieuws_radio.import_song
        end.to change(Playlist, :count).by(1)
      end
    end
  end

  # describe '#illegal_word_in_title' do
  #   context 'a title with more then 4 digits' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('test 1234')).to eq true
  #     end
  #   end
  #
  #   context 'a title with a forward slash' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('test / go ')).to eq true
  #     end
  #   end
  #
  #   context 'a title with 2 single qoutes' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title("test''s")).to eq true
  #     end
  #   end
  #
  #   context 'a titlle that has reklame or reclame' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('test reclame')).to eq true
  #     end
  #   end
  #
  #   context 'a title that has more then two dots' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('test..test')).to eq true
  #     end
  #   end
  #
  #   context 'when the title contains "nieuws"' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('ANP NIEUWS')).to eq true
  #     end
  #   end
  #
  #   context 'when the title contains "pingel"' do
  #     it 'returns false' do
  #       expect(described_class.new.illegal_word_in_title('Kerst pingel')).to eq true
  #     end
  #   end
  #
  #   context 'any other title' do
  #     it 'returns true' do
  #       expect(described_class.new.illegal_word_in_title('Liquid Spirit')).to eq false
  #     end
  #   end
  # end

  # describe '#find_or_create_artist' do
  #   context 'with multiple name' do
  #     it 'returns the artists and not a karaoke version' do
  #       spotify_track = Spotify::Track::Finder.new(artists: 'Martin Garrix & Clinton Kane', title: 'Drown')
  #       spotify_track.execute
  #       result = described_class.new.find_or_create_artist('Martin Garrix & Clinton Kane', spotify_track)
  #
  #       expect(result.map(&:name)).to contain_exactly 'Martin Garrix', 'Clinton Kane'
  #     end
  #   end
  # end

  # describe '#find_or_create_song' do
  #   let!(:song_in_your_eyes_robin_schulz) { create :song, title: 'In Your Eyes', artists: [artist_robin_schulz, artist_alida] }
  #   let!(:song_in_your_eyes_weekend) { create :song, title: 'In Your Eyes', artists: [artist_the_weeknd] }
  #   let!(:artist_the_weeknd) { create :artist, name: 'The Weeknd' }
  #   let!(:artist_robin_schulz) { create :artist, name: 'Robin Schulz' }
  #   let!(:artist_alida) { create :artist, name: 'Alida' }
  #
  #   context 'with a song present with the same name but different artist(s)' do
  #     it 'creates a new artist' do
  #       song = described_class.new.song_check([song_in_your_eyes_robin_schulz], [artist_the_weeknd], 'In Your Eyes')
  #
  #       expect(song.artists).to contain_exactly artist_the_weeknd
  #     end
  #   end
  #
  #   context 'when the song is present with the same artist(s)' do
  #     it 'doesnt create a new artist' do
  #       song = described_class.new.song_check([song_in_your_eyes_weekend], [artist_the_weeknd], 'In Your Eyes')
  #
  #       expect(song.artists).to contain_exactly artist_the_weeknd
  #     end
  #   end
  #
  #   context 'when the title is differently capitalized' do
  #     it 'it doesnt create a new song but finds the existing one' do
  #       song = nil
  #       expect do
  #         song = described_class.new.song_check([song_in_your_eyes_weekend], [artist_the_weeknd], 'In your eyes')
  #       end.to change(Playlist, :count).by(0)
  #
  #       expect(song.title).to eq 'In Your Eyes'
  #     end
  #   end
  # end
end
