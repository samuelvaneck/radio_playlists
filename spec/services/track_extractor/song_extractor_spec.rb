# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

describe TrackExtractor::SongExtractor do
  subject(:extractor) { described_class.new(played_song:, track:, artists: [artist]) }

  let(:artist) { create(:artist) }
  let(:track) do
    OpenStruct.new(
      title: 'Test Song',
      id: 'spotify123',
      isrc: 'ISRC123',
      spotify_song_url: 'https://open.spotify.com/track/spotify123',
      spotify_artwork_url: 'https://i.scdn.co/image/artwork',
      spotify_preview_url: 'https://p.scdn.co/mp3-preview/preview',
      release_date: '2023-01-01',
      release_date_precision: 'day'
    )
  end
  let(:played_song) do
    OpenStruct.new(
      title: 'Test Song',
      artist_name: 'Test Artist',
      spotify_url: 'https://open.spotify.com/track/spotify123',
      isrc_code: 'ISRC123'
    )
  end

  describe '#extract' do
    let(:song) { subject.extract }

    context 'when song does not exist' do
      it 'includes the artists' do
        expect(song.artists).to include(artist)
      end

      it 'creates a Song' do
        expect(song).to be_a(Song)
      end

      it 'sets the title' do
        expect(song.title).to eq('Test Song')
      end

      it 'sets the id on spotify' do
        expect(song.id_on_spotify).to eq('spotify123')
      end

      it 'sets the isrc code' do
        expect(song.isrcs).to include('ISRC123')
      end

      it 'sets the spotify preview URL' do
        expect(song.spotify_preview_url).to eq('https://p.scdn.co/mp3-preview/preview')
      end

      it 'sets the release date' do
        expect(song.release_date).to eq(Date.parse('2023-01-01'))
      end

      it 'sets the release date precision' do
        expect(song.release_date_precision).to eq('day')
      end
    end

    context 'when song exists' do
      let!(:existing_song) do
        create(:song,
               title: 'Test Song',
               id_on_spotify: 'spotify123',
               artists: [artist],
               spotify_preview_url: nil,
               release_date: nil)
      end

      it 'finds the existing song' do
        expect(song).to eq(existing_song)
      end

      it 'updates preview url if missing' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :spotify_preview_url).to('https://p.scdn.co/mp3-preview/preview')
      end

      it 'updates the release date if missing' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :release_date).to(Date.parse('2023-01-01'))
      end

      it 'updates the release date precision if missing' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :release_date_precision).to('day')
      end
    end

    context 'when song exists without Spotify data (found via ISRC)' do
      let!(:existing_song) do
        create(:song,
               title: 'Test Song',
               isrcs: ['ISRC123'],
               id_on_spotify: nil,
               spotify_song_url: nil,
               spotify_artwork_url: nil,
               artists: [artist])
      end

      it 'finds the existing song by ISRC' do
        expect(song).to eq(existing_song)
      end

      it 'enriches with Spotify ID' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :id_on_spotify).from(nil).to('spotify123')
      end

      it 'enriches with Spotify song URL' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :spotify_song_url).from(nil).to('https://open.spotify.com/track/spotify123')
      end

      it 'enriches with Spotify artwork URL' do
        expect do
          extractor.extract
          existing_song.reload
        end.to change(existing_song, :spotify_artwork_url).from(nil).to('https://i.scdn.co/image/artwork')
      end
    end

    context 'when song exists with Spotify data already' do
      let!(:existing_song) do
        create(:song,
               title: 'Test Song',
               id_on_spotify: 'existing_spotify_id',
               spotify_song_url: 'https://open.spotify.com/track/existing',
               spotify_artwork_url: 'https://existing-artwork.com',
               artists: [artist])
      end

      it 'does not overwrite existing Spotify ID' do
        expect do
          extractor.extract
          existing_song.reload
        end.not_to change(existing_song, :id_on_spotify)
      end

      it 'does not overwrite existing Spotify song URL' do
        expect do
          extractor.extract
          existing_song.reload
        end.not_to change(existing_song, :spotify_song_url)
      end

      it 'does not overwrite existing Spotify artwork URL' do
        expect do
          extractor.extract
          existing_song.reload
        end.not_to change(existing_song, :spotify_artwork_url)
      end
    end

    context 'when track has nil values for IDs' do
      let(:track) do
        OpenStruct.new(
          title: 'New Song',
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'New Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song_with_nil_spotify_id) do
        create(:song,
               title: 'Different Song',
               id_on_spotify: nil,
               isrcs: [],
               artists: [create(:artist, name: 'Other Artist')])
      end

      it 'does not incorrectly match existing songs with nil spotify id' do
        expect(song).not_to eq(existing_song_with_nil_spotify_id)
      end

      it 'creates a new song instead of matching nil values' do
        expect(song.title).to eq('New Song')
      end
    end

    context 'when track has nil isrc but song exists with empty isrcs' do
      let(:track) do
        OpenStruct.new(
          title: 'Another Song',
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Another Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:song_with_nil_isrc) do
        create(:song,
               title: 'Unrelated Song',
               id_on_spotify: nil,
               id_on_deezer: nil,
               id_on_itunes: nil,
               isrcs: [])
      end

      it 'does not match songs by empty isrcs' do
        expect(song).not_to eq(song_with_nil_isrc)
      end
    end

    context 'when matching by deezer id' do
      let(:track) do
        OpenStruct.new(
          title: 'Deezer Song',
          id: 'deezer456',
          isrc: nil,
          deezer_song_url: 'https://deezer.com/track/deezer456',
          deezer_artwork_url: 'https://deezer.com/artwork',
          deezer_preview_url: 'https://deezer.com/preview',
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Deezer Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_deezer_song) do
        create(:song,
               title: 'Deezer Song',
               id_on_deezer: 'deezer456',
               artists: [artist])
      end

      it 'finds the song by deezer id' do
        expect(song).to eq(existing_deezer_song)
      end
    end

    context 'when matching by itunes id' do
      let(:track) do
        OpenStruct.new(
          title: 'iTunes Song',
          id: 'itunes789',
          isrc: nil,
          itunes_song_url: 'https://music.apple.com/track/itunes789',
          itunes_artwork_url: 'https://apple.com/artwork',
          itunes_preview_url: 'https://apple.com/preview',
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'iTunes Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_itunes_song) do
        create(:song,
               title: 'iTunes Song',
               id_on_itunes: 'itunes789',
               artists: [artist])
      end

      it 'finds the song by itunes id' do
        expect(song).to eq(existing_itunes_song)
      end
    end

    context 'when track has nil deezer id but song exists with nil deezer id' do
      let(:track) do
        OpenStruct.new(
          title: 'Some Song',
          id: nil,
          isrc: nil,
          deezer_song_url: 'https://deezer.com/track/nil',
          deezer_artwork_url: nil,
          deezer_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Some Song',
          artist_name: 'Test Artist',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:song_with_nil_deezer_id) do
        create(:song,
               title: 'Other Song',
               id_on_deezer: nil)
      end

      it 'does not match songs by nil deezer id' do
        expect(song).not_to eq(song_with_nil_deezer_id)
      end
    end

    context 'when song exists with fuzzy title match' do
      let(:track) do
        OpenStruct.new(
          title: "Don\u2019t Stop Me Now",
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: "Don\u2019t Stop Me Now",
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song) do
        create(:song,
               title: "Don't Stop Me Now",
               id_on_spotify: nil,
               artists: [artist])
      end

      it 'finds the existing song via fuzzy search instead of creating a duplicate' do
        expect(song).to eq(existing_song)
      end

      it 'does not create a new song' do
        expect { song }.not_to change(Song, :count)
      end
    end

    context 'when fuzzy match exists but artist does not overlap' do
      let(:other_artist) { create(:artist, name: 'Completely Different Artist') }
      let(:track) do
        OpenStruct.new(
          title: "Don\u2019t Stop Me Now",
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: "Don\u2019t Stop Me Now",
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: nil
        )
      end

      before do
        create(:song,
               title: "Don't Stop Me Now",
               id_on_spotify: nil,
               artists: [other_artist])
      end

      it 'creates a new song with the correct artist' do
        expect(song.artists).to include(artist)
      end

      it 'does not match the existing song with different artists' do
        expect(song.artists).not_to include(other_artist)
      end
    end

    context 'when exact title match takes precedence over fuzzy match' do
      let(:track) do
        OpenStruct.new(
          title: "Don't Stop Me Now",
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: "Don't Stop Me Now",
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song) do
        create(:song,
               title: "Don't Stop Me Now",
               id_on_spotify: 'exact123',
               artists: [artist])
      end

      it 'finds the exact match' do
        expect(song).to eq(existing_song)
      end

      it 'does not create a new song' do
        expect { song }.not_to change(Song, :count)
      end
    end

    context 'when title has accent differences' do
      let(:track) do
        OpenStruct.new(
          title: 'Señorita',
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Señorita',
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song) do
        create(:song,
               title: 'Senorita',
               id_on_spotify: nil,
               artists: [artist])
      end

      it 'finds the existing song via fuzzy search despite accent difference' do
        expect(song).to eq(existing_song)
      end

      it 'does not create a duplicate song' do
        expect { song }.not_to change(Song, :count)
      end
    end

    context 'when title has extra parenthetical info' do
      let(:track) do
        OpenStruct.new(
          title: 'Flowers (Radio Edit)',
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Flowers (Radio Edit)',
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song) do
        create(:song,
               title: 'Flowers',
               id_on_spotify: nil,
               artists: [artist])
      end

      it 'finds the existing song via fuzzy search' do
        expect(song).to eq(existing_song)
      end
    end

    context 'when fuzzy search has no artists' do
      subject(:extractor) { described_class.new(played_song:, track:, artists: []) }

      let(:track) do
        OpenStruct.new(
          title: "Don\u2019t Stop Me Now",
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: "Don\u2019t Stop Me Now",
          artist_name: '',
          spotify_url: nil,
          isrc_code: nil
        )
      end

      before do
        create(:song,
               title: "Don't Stop Me Now",
               id_on_spotify: nil,
               artists: [create(:artist, name: 'Queen')])
      end

      it 'does not use fuzzy search and creates the song without artists' do
        expect(song.artists).to be_empty
      end
    end

    context 'when fuzzy match exists with multiple artists' do
      let(:second_artist) { create(:artist, name: 'Second Artist') }

      let(:track) do
        OpenStruct.new(
          title: "Don\u2019t Stop Me Now",
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: "Don\u2019t Stop Me Now",
          artist_name: "#{artist.name} feat. #{second_artist.name}",
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song) do
        create(:song,
               title: "Don't Stop Me Now",
               id_on_spotify: nil,
               artists: [artist, second_artist])
      end

      it 'finds the existing song when both artists match' do
        expect(song).to eq(existing_song)
      end
    end

    context 'when fuzzy match exists with different dash type in title' do
      let(:track) do
        OpenStruct.new(
          title: "Re\u2013Start",
          id: nil,
          isrc: nil,
          spotify_song_url: nil,
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: "Re\u2013Start",
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song) do
        create(:song,
               title: 'Re-Start',
               id_on_spotify: nil,
               artists: [artist])
      end

      it 'finds the existing song via fuzzy search despite dash difference' do
        expect(song).to eq(existing_song)
      end
    end

    context 'when fuzzy match finds a different song by the same artist' do
      let(:track) { nil }
      let(:played_song) do
        OpenStruct.new(
          title: 'Laat Het Licht Aan',
          artist_name: 'Snelle',
          spotify_url: nil,
          isrc_code: nil
        )
      end
      let(:artist) { create(:artist, name: 'Snelle') }

      before do
        create(:song, title: 'Ik Zing (feat. Snelle)', id_on_spotify: 'ikzing123', artists: [artist])
      end

      it 'does not match the wrong song with a dissimilar title', :aggregate_failures do
        expect(song.title).to eq('Laat Het Licht Aan')
        expect(song.id).not_to eq(Song.find_by(title: 'Ik Zing (feat. Snelle)')&.id)
      end
    end

    context 'when same artist has multiple songs and fuzzy search should pick the right one' do
      let(:track) { nil }
      let(:played_song) do
        OpenStruct.new(
          title: 'Laat Het Licht Aan',
          artist_name: 'Snelle',
          spotify_url: nil,
          isrc_code: nil
        )
      end
      let(:artist) { create(:artist, name: 'Snelle') }

      before do
        create(:song, title: 'Ik Zing (feat. Snelle)', id_on_spotify: 'ikzing123', artists: [artist])
        create(:song, title: 'Laat Het Licht Aan', id_on_spotify: 'laat123', artists: [artist])
      end

      it 'finds the correct song with matching title' do
        expect(song).to eq(Song.find_by(title: 'Laat Het Licht Aan'))
      end
    end

    context 'when fuzzy search encounters two different songs by same artist' do
      let(:track) { nil }
      let(:played_song) do
        OpenStruct.new(
          title: 'Sluit Me In Je Armen',
          artist_name: 'Snelle',
          spotify_url: nil,
          isrc_code: nil
        )
      end
      let(:artist) { create(:artist, name: 'Snelle') }

      before do
        create(:song, title: 'Laat Het Licht Aan', id_on_spotify: 'laat123', artists: [artist])
      end

      it 'creates a new song instead of matching a dissimilar title', :aggregate_failures do
        expect(song.title).to eq('Sluit Me In Je Armen')
        expect(song).not_to eq(Song.find_by(title: 'Laat Het Licht Aan'))
      end
    end

    context 'when played title is a substring of existing song with feat info' do
      let(:track) { nil }
      let(:played_song) do
        OpenStruct.new(
          title: 'Ik Zing',
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: nil
        )
      end
      let(:artist) { create(:artist, name: 'Zoë Livay') }

      let!(:existing_song) do
        create(:song, title: 'Ik Zing (feat. Snelle)', id_on_spotify: 'ikzing123', artists: [artist])
      end

      it 'matches the existing song because title similarity is above threshold' do
        expect(song).to eq(existing_song)
      end
    end

    context 'when similar but not identical titles exist for the same artist' do
      let(:track) { nil }
      let(:played_song) do
        OpenStruct.new(
          title: 'Laat Het Licht Aan',
          artist_name: 'Snelle',
          spotify_url: nil,
          isrc_code: nil
        )
      end
      let(:artist) { create(:artist, name: 'Snelle') }

      let!(:existing_song) do
        create(:song, title: 'Laat Het Licht Uit', id_on_spotify: 'lichtuit123', artists: [artist])
      end

      it 'matches the similar title above threshold' do
        expect(song).to eq(existing_song)
      end
    end

    context 'when song exists with different Spotify ID but same ISRC' do
      let(:track) do
        OpenStruct.new(
          track: { 'id' => 'spotify_solo_version' },
          title: 'Zwart Wit',
          id: 'spotify_solo_version',
          isrc: 'NLA200200321',
          spotify_song_url: 'https://open.spotify.com/track/spotify_solo_version',
          spotify_artwork_url: 'https://i.scdn.co/image/solo',
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Zwart Wit',
          artist_name: 'Frank Boeijen',
          spotify_url: 'https://open.spotify.com/track/spotify_solo_version',
          isrc_code: 'NLA200200321'
        )
      end

      let!(:existing_song_with_different_spotify_id) do
        create(:song,
               title: 'Zwart Wit',
               id_on_spotify: 'spotify_band_version',
               isrcs: ['NLA200200321'],
               artists: [create(:artist, name: 'Frank Boeijen Groep')])
      end

      it 'finds the existing song by ISRC instead of creating a duplicate' do
        expect(song).to eq(existing_song_with_different_spotify_id)
      end

      it 'does not create a new song' do
        expect { song }.not_to change(Song, :count)
      end

      it 'does not add the ISRC again since it already exists on the song' do
        extractor.extract
        existing_song_with_different_spotify_id.reload
        expect(existing_song_with_different_spotify_id.isrcs).to eq(['NLA200200321'])
      end
    end

    context 'when ISRC matches a song with a completely different title (cross-contamination)' do
      subject(:extractor) { described_class.new(played_song:, track:, artists: [snelle]) }

      let(:snelle) { create(:artist, name: 'Snelle') }
      let(:track) do
        OpenStruct.new(
          track: { 'id' => 'laat_het_licht_aan_spotify' },
          title: 'Laat Het Licht Aan',
          id: 'laat_het_licht_aan_spotify',
          isrc: 'NLS242600073',
          spotify_song_url: 'https://open.spotify.com/track/laat_het_licht_aan_spotify',
          spotify_artwork_url: 'https://i.scdn.co/image/laat',
          spotify_preview_url: nil,
          release_date: '2026-03-19',
          release_date_precision: 'day'
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Laat Het Licht Aan',
          artist_name: 'Snelle',
          spotify_url: 'https://open.spotify.com/track/laat_het_licht_aan_spotify',
          isrc_code: nil
        )
      end
      let!(:ik_zing_song) do
        create(:song,
               title: 'Ik Zing (feat. Snelle)',
               id_on_spotify: 'ik_zing_spotify',
               isrcs: %w[NLA802500027 NLS242600073],
               artists: [zoe, snelle])
      end
      let(:zoe) { create(:artist, name: 'Zoë Livay') }

      it 'skips the contaminated ISRC match and creates the correct song', :aggregate_failures do
        song = extractor.extract

        expect(song).not_to eq(ik_zing_song)
        expect(song.title).to eq('Laat Het Licht Aan')
        expect(song.id_on_spotify).to eq('laat_het_licht_aan_spotify')
      end

      it 'does not modify the contaminated song', :aggregate_failures do
        extractor.extract
        ik_zing_song.reload

        expect(ik_zing_song.isrcs).to eq(%w[NLA802500027 NLS242600073])
        expect(ik_zing_song.id_on_spotify).to eq('ik_zing_spotify')
      end
    end

    context 'when should_add_isrc? prevents cross-contamination for new ISRCs' do
      subject(:extractor) { described_class.new(played_song:, track:, artists: [artist]) }

      let(:track) do
        OpenStruct.new(
          track: { 'id' => 'different_spotify_id' },
          title: 'Different Song',
          id: 'different_spotify_id',
          isrc: 'NEW_ISRC_123',
          spotify_song_url: 'https://open.spotify.com/track/different_spotify_id',
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Different Song',
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: nil
        )
      end

      let!(:existing_song) do
        create(:song,
               title: 'Existing Song',
               id_on_spotify: 'existing_spotify_id',
               isrcs: ['EXISTING_ISRC'],
               artists: [artist])
      end

      it 'does not add ISRC from a track with a different Spotify ID', :aggregate_failures do
        # Simulate the case where find_by_track matched via ISRC (wrong match)
        # The song already has an ISRC, and the track has a different Spotify ID
        # build_spotify_updates should refuse to add the new ISRC
        song_result = extractor.extract
        # The extractor won't find existing_song (different IDs), so it creates a new one
        expect(song_result).not_to eq(existing_song)
        existing_song.reload
        expect(existing_song.isrcs).to eq(['EXISTING_ISRC'])
      end
    end

    context 'when ISRC matches a song with subtitle differences in title' do
      let(:track) do
        OpenStruct.new(
          track: { 'id' => 'spotify_good' },
          title: "I'm Good - From The Movie \"GOAT\"",
          id: 'spotify_good',
          isrc: 'USRC12345',
          spotify_song_url: 'https://open.spotify.com/track/spotify_good',
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: "I'm Good - From The Movie \"GOAT\"",
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: 'USRC12345'
        )
      end

      let!(:existing_song) do
        create(:song,
               title: "I'm Good",
               id_on_spotify: 'spotify_good',
               isrcs: ['USRC12345'],
               artists: [artist])
      end

      it 'matches the existing song despite subtitle differences' do
        expect(song).to eq(existing_song)
      end
    end

    context 'when ISRC matches a song with featured artist differences in title' do
      let(:track) do
        OpenStruct.new(
          track: { 'id' => 'spotify_pgd' },
          title: 'PGD (feat. Kyle Richh & ZEDDY WILL)',
          id: 'spotify_pgd',
          isrc: 'USRC67890',
          spotify_song_url: 'https://open.spotify.com/track/spotify_pgd',
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'PGD (feat. Kyle Richh & ZEDDY WILL)',
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: 'USRC67890'
        )
      end

      let!(:existing_song) do
        create(:song,
               title: 'Pgd',
               id_on_spotify: 'spotify_pgd',
               isrcs: ['USRC67890'],
               artists: [artist])
      end

      it 'matches the existing song despite featured artist differences' do
        expect(song).to eq(existing_song)
      end
    end

    context 'when song has no Spotify ID and track adds an ISRC' do
      subject(:extractor) { described_class.new(played_song:, track:, artists: [artist]) }

      let(:track) do
        OpenStruct.new(
          track: { 'id' => 'new_spotify_id' },
          title: 'Test Song',
          id: 'new_spotify_id',
          isrc: 'NEW_ISRC',
          spotify_song_url: 'https://open.spotify.com/track/new_spotify_id',
          spotify_artwork_url: nil,
          spotify_preview_url: nil,
          release_date: nil,
          release_date_precision: nil
        )
      end
      let(:played_song) do
        OpenStruct.new(
          title: 'Test Song',
          artist_name: artist.name,
          spotify_url: nil,
          isrc_code: 'EXISTING_ISRC'
        )
      end

      let!(:existing_song) do
        create(:song,
               title: 'Test Song',
               id_on_spotify: nil,
               isrcs: ['EXISTING_ISRC'],
               artists: [artist])
      end

      it 'adds the ISRC when the song has no Spotify ID yet' do
        extractor.extract
        existing_song.reload
        expect(existing_song.isrcs).to contain_exactly('EXISTING_ISRC', 'NEW_ISRC')
      end
    end
  end
end
