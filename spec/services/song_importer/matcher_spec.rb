# frozen_string_literal: true

describe SongImporter::Matcher do
  subject(:matcher) do
    described_class.new(radio_station: radio_station, song: song)
  end

  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Test Artist') }
  let(:song) { create(:song, title: 'Test Song', artists: [artist]) }

  describe '#matches_any_played_last_hour?' do
    context 'when no songs were played in the last hour' do
      it 'returns false' do
        expect(matcher.matches_any_played_last_hour?).to be false
      end
    end

    context 'when the same song was played in the last hour' do
      before do
        create(:air_play, radio_station: radio_station, song: song, created_at: 30.minutes.ago)
      end

      it 'returns true' do
        expect(matcher.matches_any_played_last_hour?).to be true
      end
    end

    context 'when a similar song was played in the last hour' do
      let(:similar_song) { create(:song, title: 'Test Song', artists: [artist]) }

      before do
        create(:air_play, radio_station: radio_station, song: similar_song, created_at: 30.minutes.ago)
      end

      it 'returns true for high similarity' do
        expect(matcher.matches_any_played_last_hour?).to be true
      end
    end

    context 'when a different song by the same artist was played in the last hour' do
      let(:different_song_same_artist) { create(:song, title: 'Completely Different Title', artists: [artist]) }

      before do
        create(:air_play, radio_station: radio_station, song: different_song_same_artist, created_at: 30.minutes.ago)
      end

      it 'returns false because title does not match' do
        expect(matcher.matches_any_played_last_hour?).to be false
      end
    end

    context 'when a completely different song was played in the last hour' do
      let(:different_artist) { create(:artist, name: 'Different Artist') }
      let(:different_song) { create(:song, title: 'Completely Different', artists: [different_artist]) }

      before do
        create(:air_play, radio_station: radio_station, song: different_song, created_at: 30.minutes.ago)
      end

      it 'returns false' do
        expect(matcher.matches_any_played_last_hour?).to be false
      end
    end

    context 'when songs were played more than an hour ago' do
      before do
        create(:air_play, radio_station: radio_station, song: song, created_at: 2.hours.ago)
      end

      it 'returns false' do
        expect(matcher.matches_any_played_last_hour?).to be false
      end
    end
  end

  describe '#song_matches' do
    context 'when no songs were played in the last hour' do
      it 'returns an empty array' do
        expect(matcher.song_matches).to eq([])
      end
    end

    context 'when songs were played in the last hour' do
      let(:different_artist) { create(:artist, name: 'Different Artist') }
      let(:different_song) { create(:song, title: 'Completely Different', artists: [different_artist]) }

      before do
        create(:air_play, radio_station: radio_station, song: different_song, created_at: 30.minutes.ago)
      end

      it 'returns an array' do
        expect(matcher.song_matches).to be_an(Array)
      end

      it 'returns hashes' do
        expect(matcher.song_matches.first).to be_a(Hash)
      end

      it 'returns hashes with artist_similarity key' do
        expect(matcher.song_matches.first).to have_key(:artist_similarity)
      end

      it 'returns hashes with title_similarity key' do
        expect(matcher.song_matches.first).to have_key(:title_similarity)
      end

      it 'returns integer artist_similarity scores' do
        expect(matcher.song_matches.first[:artist_similarity]).to be_an(Integer)
      end

      it 'returns integer title_similarity scores' do
        expect(matcher.song_matches.first[:title_similarity]).to be_an(Integer)
      end
    end
  end

  describe '#song_match' do
    let(:different_artist) { create(:artist, name: 'Different Artist') }

    context 'when comparing identical songs' do
      let(:identical_song) { create(:song, title: 'Test Song', artists: [artist]) }

      it 'returns 100' do
        expect(matcher.song_match(identical_song)).to eq(100)
      end
    end

    context 'when comparing similar songs' do
      let(:similar_song) { create(:song, title: 'Test Songs', artists: [artist]) }

      it 'returns a high similarity score' do
        expect(matcher.song_match(similar_song)).to be > 80
      end
    end

    context 'when comparing different song by same artist' do
      let(:different_song_same_artist) { create(:song, title: 'Completely Different Title', artists: [artist]) }

      it 'returns a low similarity score due to title mismatch' do
        # Artist matches 100%, but title is very different
        # song_match returns the minimum of artist and title similarity
        expect(matcher.song_match(different_song_same_artist)).to be < 60
      end
    end

    context 'when comparing different songs' do
      let(:different_song) { create(:song, title: 'XYZ Unrelated Track ABC', artists: [different_artist]) }

      it 'returns a low similarity score' do
        # Using very different strings to ensure low JaroWinkler similarity
        expect(matcher.song_match(different_song)).to be < 60
      end
    end

    context 'when comparing songs with multiple artists' do
      let(:artist2) { create(:artist, name: 'Second Artist') }
      let(:multi_artist_song) { create(:song, title: 'Test Song', artists: [artist, artist2]) }

      it 'includes all artist names in comparison' do
        score = matcher.song_match(multi_artist_song)
        expect(score).to be > 70
      end
    end
  end

  describe '#artist_match' do
    context 'when comparing identical artists' do
      let(:same_artist_song) { create(:song, title: 'Different Title', artists: [artist]) }

      it 'returns 100' do
        expect(matcher.artist_match(same_artist_song)).to eq(100)
      end
    end

    context 'when comparing similar artists' do
      let(:similar_artist) { create(:artist, name: 'Test Artists') }
      let(:similar_artist_song) { create(:song, title: 'Different Title', artists: [similar_artist]) }

      it 'returns a high similarity score' do
        expect(matcher.artist_match(similar_artist_song)).to be > 80
      end
    end

    context 'when comparing different artists' do
      let(:different_artist) { create(:artist, name: 'Completely Different Name') }
      let(:different_artist_song) { create(:song, title: 'Test Song', artists: [different_artist]) }

      it 'returns a low similarity score' do
        expect(matcher.artist_match(different_artist_song)).to be < 60
      end
    end
  end

  describe '#title_match' do
    context 'when comparing identical titles' do
      let(:same_title_song) { create(:song, title: 'Test Song', artists: [create(:artist, name: 'Other Artist')]) }

      it 'returns 100' do
        expect(matcher.title_match(same_title_song)).to eq(100)
      end
    end

    context 'when comparing similar titles' do
      let(:similar_title_song) { create(:song, title: 'Test Songs', artists: [artist]) }

      it 'returns a high similarity score' do
        expect(matcher.title_match(similar_title_song)).to be > 80
      end
    end

    context 'when comparing different titles' do
      let(:different_title_song) { create(:song, title: 'Completely Different Title', artists: [artist]) }

      it 'returns a low similarity score' do
        expect(matcher.title_match(different_title_song)).to be < 60
      end
    end
  end

  describe 'performance optimization' do
    context 'when using map instead of find_each.map' do
      before do
        Array.new(5) do |i|
          different_artist = create(:artist, name: "Artist #{i}")
          different_song = create(:song, title: "Song #{i}", artists: [different_artist])
          create(:air_play, radio_station: radio_station, song: different_song,
                            created_at: (i + 1).minutes.ago, broadcasted_at: (i + 1).minutes.ago)
        end
      end

      it 'returns correct number of scores' do
        expect(matcher.song_matches.length).to eq(5)
      end

      it 'returns all results as hashes' do
        expect(matcher.song_matches).to all(be_a(Hash))
      end

      it 'includes similarity scores in all results' do
        expect(matcher.song_matches).to all(include(:artist_similarity, :title_similarity))
      end
    end
  end

  describe 'edge cases' do
    context 'when song title is nil' do
      let(:song_with_nil_title) { create(:song, title: nil, artists: [artist]) }

      it 'handles nil title gracefully' do
        expect { matcher.song_match(song_with_nil_title) }.not_to raise_error
      end
    end

    context 'when song has no artists' do
      let(:song_without_artists) { create(:song, title: 'No Artists Song') }

      it 'handles missing artists gracefully' do
        expect { matcher.song_match(song_without_artists) }.not_to raise_error
      end
    end

    context 'when comparing against song with empty search text' do
      let(:empty_search_song) { create(:song, title: '', artists: []) }

      before do
        create(:air_play, radio_station: radio_station, song: empty_search_song, created_at: 30.minutes.ago)
      end

      it 'handles empty search text gracefully' do
        expect { matcher.matches_any_played_last_hour? }.not_to raise_error
      end
    end
  end
end
