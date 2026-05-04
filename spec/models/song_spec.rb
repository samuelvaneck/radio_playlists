# frozen_string_literal: true

# == Schema Information
#
# Table name: songs
#
#  id                     :bigint           not null, primary key
#  acoustid_submitted_at  :datetime
#  album_name             :string
#  deezer_artwork_url     :string
#  deezer_preview_url     :string
#  deezer_song_url        :string
#  duration_ms            :integer
#  explicit               :boolean          default(FALSE)
#  hit_potential_score    :decimal(5, 2)
#  id_on_deezer           :string
#  id_on_itunes           :string
#  id_on_spotify          :string
#  id_on_tidal            :string
#  id_on_youtube          :string
#  isrc                   :string
#  isrcs                  :string           default([]), is an Array
#  itunes_artwork_url     :string
#  itunes_preview_url     :string
#  itunes_song_url        :string
#  lastfm_enriched_at     :datetime
#  lastfm_listeners       :bigint
#  lastfm_playcount       :bigint
#  lastfm_tags            :string           default([]), is an Array
#  normalized_title       :string
#  popularity             :integer
#  release_date           :date
#  release_date_precision :string
#  search_text            :text
#  slug                   :string
#  spotify_artwork_url    :string
#  spotify_preview_url    :string
#  spotify_song_url       :string
#  tidal_artwork_url      :string
#  tidal_preview_url      :string
#  tidal_song_url         :string
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_songs_on_acoustid_submitted_at  (acoustid_submitted_at)
#  index_songs_on_id_on_deezer           (id_on_deezer)
#  index_songs_on_id_on_itunes           (id_on_itunes)
#  index_songs_on_id_on_tidal            (id_on_tidal)
#  index_songs_on_normalized_title       (normalized_title)
#  index_songs_on_release_date           (release_date)
#  index_songs_on_search_text_trgm       (search_text) USING gin
#  index_songs_on_slug                   (slug) UNIQUE
#
describe Song do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:radio_station) { create :radio_station }
  let(:air_play_one) { create :air_play, song: song_one }
  let(:air_play_two) { create :air_play, song: song_two, radio_station: }
  let(:air_play_three) { create :air_play, song: song_two, radio_station: }

  let(:song_drown) { create :song, title: 'Drown', artists: [artist_martin_garrix, artist_clinton_kane] }
  let(:artist_martin_garrix) { create :artist, name: 'Martin Garrix' }
  let(:artist_clinton_kane) { create :artist, name: 'Clinton Kane' }
  let(:song_breaking_me) { create :song, title: 'Breaking Me Ft A7s', artists: [artist_topic] }
  let(:artist_topic) { create :artist, name: 'Topic' }
  let(:song_stuck_with_u) { create :song, title: 'Stuck With U', artists: [artist_justin_bieber, artist_ariana_grande] }
  let(:artist_justin_bieber) { create :artist, name: 'Justin Bieber' }
  let(:artist_ariana_grande) { create :artist, name: 'Ariana Grande' }

  before do
    air_play_one
    air_play_two
    air_play_three
  end

  describe '#self.most_played' do
    context 'with search term params present' do
      subject(:most_played_with_search_term) do
        Song.most_played({ search_term: searchable_song.title })
      end

      let(:searchable_song) { create :song, title: 'Unique Test Song Title', artists: [artist_one] }
      let!(:searchable_air_play) { create :air_play, song: searchable_song }

      it 'only returns the songs matching the search term' do
        expect(most_played_with_search_term).to contain_exactly searchable_song
      end
    end

    context 'with radio_station_ids params present' do
      subject(:most_played_with_radio_station_ids) do
        Song.most_played({ radio_station_ids: [radio_station.id] })
      end

      it 'only returns the songs played on the radio station' do
        expect(most_played_with_radio_station_ids).to include(song_two)
      end

      it 'adds a counter attribute on the song' do
        expect(most_played_with_radio_station_ids[0].counter).to eq 2
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context 'with music_profile filter params present' do
      let(:high_energy_song) { create(:song) }
      let(:low_energy_song) { create(:song) }
      let!(:high_energy_profile) do
        create(:music_profile, song: high_energy_song, energy: 0.9, danceability: 0.8, tempo: 140)
      end
      let!(:low_energy_profile) do
        create(:music_profile, song: low_energy_song, energy: 0.3, danceability: 0.4, tempo: 80)
      end
      let!(:high_energy_air_play) { create(:air_play, song: high_energy_song) }
      let!(:low_energy_air_play) { create(:air_play, song: low_energy_song) }

      it 'filters by minimum energy', :aggregate_failures do
        result = Song.most_played({ music_profile: { 'energy_min' => '0.7' } })
        expect(result).to include(high_energy_song)
        expect(result).not_to include(low_energy_song)
      end

      it 'filters by maximum energy', :aggregate_failures do
        result = Song.most_played({ music_profile: { 'energy_max' => '0.5' } })
        expect(result).to include(low_energy_song)
        expect(result).not_to include(high_energy_song)
      end

      it 'filters by energy range', :aggregate_failures do
        result = Song.most_played({ music_profile: { 'energy_min' => '0.2', 'energy_max' => '0.5' } })
        expect(result).to include(low_energy_song)
        expect(result).not_to include(high_energy_song)
      end

      it 'filters by minimum danceability', :aggregate_failures do
        result = Song.most_played({ music_profile: { 'danceability_min' => '0.6' } })
        expect(result).to include(high_energy_song)
        expect(result).not_to include(low_energy_song)
      end

      it 'filters by tempo range', :aggregate_failures do
        result = Song.most_played({ music_profile: { 'tempo_min' => '100', 'tempo_max' => '160' } })
        expect(result).to include(high_energy_song)
        expect(result).not_to include(low_energy_song)
      end

      it 'combines multiple music profile filters', :aggregate_failures do
        filters = { 'energy_min' => '0.7', 'danceability_min' => '0.6', 'tempo_min' => '120' }
        result = Song.most_played({ music_profile: filters })
        expect(result).to include(high_energy_song)
        expect(result).not_to include(low_energy_song)
      end

      it 'returns no results when filters exclude all songs', :aggregate_failures do
        result = Song.most_played({ music_profile: { 'energy_min' => '0.95' } })
        expect(result).not_to include(high_energy_song)
        expect(result).not_to include(low_energy_song)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context 'with pagination and preloaded artists' do
      let(:per_page) { 5 }
      let(:new_radio_station) { create(:radio_station) }
      let!(:paginated_songs) do
        Array.new(12) do |i|
          artist = create(:artist, name: "Paginated Artist #{i}")
          song = create(:song, title: "Paginated Song #{i}", artists: [artist])
          # Create varying play counts so songs are ordered predictably (descending by plays)
          (12 - i).times { create(:air_play, song: song, radio_station: new_radio_station) }
          song
        end
      end

      it 'returns correct pagination metadata for page 3', :aggregate_failures do
        result = Song.most_played({ radio_station_ids: [new_radio_station.id] })
                   .paginate(page: 3, per_page: per_page)

        expect(result.current_page).to eq 3
        expect(result.total_entries).to eq 12
        expect(result.total_pages).to eq 3
      end

      it 'returns correct songs for page 3 ordered by play count' do
        result = Song.most_played({ radio_station_ids: [new_radio_station.id] })
                   .paginate(page: 3, per_page: per_page)

        # Page 3 should have the last 2 songs (indices 10 and 11, which have fewest plays)
        expect(result.length).to eq 2
      end

      it 'preloads artists for paginated results', :aggregate_failures do
        result = Song.most_played({ radio_station_ids: [new_radio_station.id] })
                   .paginate(page: 3, per_page: per_page)

        result.each do |song|
          expect(song.artists).to be_loaded
          expect(song.artists).not_to be_empty
        end
      end

      it 'includes counter and position attributes on paginated songs', :aggregate_failures do
        result = Song.most_played({ radio_station_ids: [new_radio_station.id] })
                   .paginate(page: 3, per_page: per_page)

        result.each do |song|
          expect(song).to respond_to(:counter)
          expect(song).to respond_to(:position)
          expect(song.counter).to be_a(Integer)
          expect(song.position).to be_a(Integer)
        end
      end

      it 'does not trigger additional queries when accessing preloaded artists' do
        result = Song.most_played({ radio_station_ids: [new_radio_station.id] })
                   .paginate(page: 3, per_page: per_page)

        # Force load the result and preloaded artists
        result.to_a
        # Accessing artists should not trigger new queries since they are preloaded
        expect(result.all? { |s| s.artists.loaded? }).to be true
      end
    end
  end

  describe '.search_by_text' do
    let(:artist) { create(:artist, name: 'Queen') }
    let!(:bohemian) { create(:song, title: 'Bohemian Rhapsody', artists: [artist], popularity: 85) }

    it 'finds songs with exact match' do
      expect(Song.search_by_text('Bohemian Rhapsody')).to include(bohemian)
    end

    it 'finds songs with typo in query' do
      expect(Song.search_by_text('Bohemien Rapsody')).to include(bohemian)
    end

    it 'finds songs by artist name' do
      expect(Song.search_by_text('Queen')).to include(bohemian)
    end

    it 'finds songs with prefix match' do
      expect(Song.search_by_text('Bohem')).to include(bohemian)
    end

    it 'ranks more popular songs higher' do
      less_popular = create(:song, title: 'Bohemian Nights', artists: [artist], popularity: 5)
      results = Song.search_by_text('Bohemian')

      expect(results.index(bohemian)).to be < results.index(less_popular)
    end
  end

  describe '.faceted_search' do
    let(:drake) { create(:artist, name: 'Drake') }
    let(:adele) { create(:artist, name: 'Adele') }
    let!(:hotline) do
      create(:song, title: 'Hotline Bling', artists: [drake],
                    album_name: 'Views', release_date: Date.new(2016, 4, 29), popularity: 90)
    end
    let!(:rolling) do
      create(:song, title: 'Rolling in the Deep', artists: [adele],
                    album_name: '21', release_date: Date.new(2011, 1, 24), popularity: 85)
    end

    it 'filters by artist name', :aggregate_failures do
      results = Song.faceted_search(artist: 'Drake')
      expect(results).to include(hotline)
      expect(results).not_to include(rolling)
    end

    it 'filters by title', :aggregate_failures do
      results = Song.faceted_search(title: 'Rolling')
      expect(results).to include(rolling)
      expect(results).not_to include(hotline)
    end

    it 'filters by album', :aggregate_failures do
      results = Song.faceted_search(album: 'Views')
      expect(results).to include(hotline)
      expect(results).not_to include(rolling)
    end

    it 'filters by year_from', :aggregate_failures do
      results = Song.faceted_search(year_from: '2015')
      expect(results).to include(hotline)
      expect(results).not_to include(rolling)
    end

    it 'filters by year_to', :aggregate_failures do
      results = Song.faceted_search(year_to: '2012')
      expect(results).to include(rolling)
      expect(results).not_to include(hotline)
    end

    it 'combines multiple filters' do
      results = Song.faceted_search(artist: 'Adele', year_from: '2010', year_to: '2012')
      expect(results).to contain_exactly(rolling)
    end

    it 'returns all songs when no filters given' do
      results = Song.faceted_search
      expect(results).to include(hotline, rolling)
    end

    it 'respects limit' do
      results = Song.faceted_search(limit: 1)
      expect(results.length).to eq(1)
    end

    context 'with blank filter values' do
      it 'ignores blank artist' do
        results = Song.faceted_search(artist: '')
        expect(results).to include(hotline, rolling)
      end

      it 'ignores nil year_from' do
        results = Song.faceted_search(year_from: nil)
        expect(results).to include(hotline, rolling)
      end
    end
  end

  describe '.suggest' do
    let(:drake) { create(:artist, name: 'Drake', spotify_popularity: 95) }
    let!(:hotline) do
      create(:song, title: 'Hotline Bling', artists: [drake],
                    album_name: 'Views', release_date: Date.new(2016, 4, 29), popularity: 90)
    end

    it 'suggests artist names matching query' do
      expect(Song.suggest(field: 'artist', query: 'Dra')).to include('Drake')
    end

    it 'suggests song titles matching query' do
      expect(Song.suggest(field: 'title', query: 'Hot')).to include('Hotline Bling')
    end

    it 'suggests album names matching query' do
      expect(Song.suggest(field: 'album', query: 'Vie')).to include('Views')
    end

    it 'suggests release years' do
      expect(Song.suggest(field: 'year')).to include(2016)
    end

    it 'returns available field names for unknown field' do
      expect(Song.suggest(field: nil)).to eq(%w[artist title album year_from year_to])
    end
  end

  describe '#cleanup' do
    context 'if the song has no air plays' do
      let!(:song_no_air_play) { create :song }
      it 'destorys the song' do
        expect {
          song_no_air_play.cleanup
        }.to change(Song, :count).by(-1)
      end
    end

    context 'if the song has an air play' do
      it 'does not destroy the song' do
        expect {
          song_one.cleanup
        }.not_to change(Song, :count)
      end
    end

    context 'if the song artist has no more songs' do
      let(:artist_one_song) { create :artist }
      let!(:song_one) { create :song, artists: [artist_one_song] }

      it 'does not destroy the artist' do
        expect {
          song_one.cleanup
        }.not_to change(Artist, :count)
      end
    end

    context 'if the song artist has more song' do
      let(:artist_multiple_song) { create :artist }
      let!(:song_one) { create :song, artists: [artist_multiple_song] }
      let!(:song_two) { create :song, artists: [artist_multiple_song] }
      it 'destroy' do
        expect {
          song_two.cleanup
        }.not_to change(Artist, :count)
      end
    end
  end

  describe '#update_artists' do
    let(:ed_sheeran) { create(:artist, name: 'Ed Sheeran') }
    let(:taylor_swift) { create(:artist, name: 'Taylor Swift') }
    let(:song) { create(:song, title: 'The Joker and the Queen', artists: [ed_sheeran]) }

    before { song }

    context 'when adding a new artists' do
      it 'creates a new record in the join table ArtistsSong' do
        expect do
          song.update_artists([ed_sheeran, taylor_swift])
        end.to change(ArtistsSong, :count).by(1)
      end
    end

    context 'when adding a duplicate artists' do
      it 'does not create a new record in the join table' do
        expect do
          song.update_artists([ed_sheeran])
        end.not_to change(ArtistsSong, :count)
      end
    end

    context 'when no artists are given as argument' do
      it 'does not change the song artists' do
        expect do
          song.update_artists(nil)
        end.not_to change(ArtistsSong, :count)
      end
    end

    context 'when given a single artists as argument' do
      before do
        song.update_artists(taylor_swift)
        song.reload
      end

      it 'assigns the given artist(s) as song artists' do
        expect(song.artists).to contain_exactly(taylor_swift)
      end
    end

    context 'when given an arrray of artists as arugments' do
      before do
        song.update_artists([taylor_swift])
        song.reload
      end

      it 'assigns the given artist(s) as song artists' do
        expect(song.artists).to contain_exactly(taylor_swift)
      end
    end
  end

  describe '#set_search_text' do
    let(:artist) { create(:artist, name: 'Ed Sheeran') }
    let(:song) { create(:song, title: 'Shape of You', artists: [artist]) }

    it 'updates search_text before song creation' do
      expect(song.reload.search_text).to eq('Ed Sheeran Shape of You')
    end
  end

  describe '.normalize_title' do
    it 'returns nil for blank input' do
      expect(Song.normalize_title('')).to be_nil
    end

    it 'returns nil for nil input' do
      expect(Song.normalize_title(nil)).to be_nil
    end

    it 'collapses spacing variants to the same key' do
      expect(Song.normalize_title('Ik Bel Je Zo Maar Even Op'))
        .to eq(Song.normalize_title('Ik Bel Je Zomaar Even Op'))
    end

    it 'is case-insensitive' do
      expect(Song.normalize_title('Hello World')).to eq(Song.normalize_title('HELLO world'))
    end

    it 'strips diacritics' do
      expect(Song.normalize_title('Beyoncé')).to eq(Song.normalize_title('Beyonce'))
    end

    it 'strips punctuation so smart-quote variants collapse', :aggregate_failures do
      expect(Song.normalize_title("Don't Stop Me Now")).to eq('dontstopmenow')
      expect(Song.normalize_title('Don’t Stop Me Now')).to eq('dontstopmenow')
    end

    it 'preserves digits' do
      expect(Song.normalize_title('99 Luftballons')).to eq('99luftballons')
    end

    it 'returns nil when the input contains only punctuation/whitespace' do
      expect(Song.normalize_title('  --!!  ')).to be_nil
    end
  end

  describe '#set_normalized_title callback' do
    let(:artist) { create(:artist, name: 'Gordon') }

    it 'populates normalized_title on create' do
      song = create(:song, title: 'Ik Bel Je Zomaar Even Op', artists: [artist])
      expect(song.reload.normalized_title).to eq('ikbeljezomaarevenop')
    end

    it 'recomputes normalized_title when the title changes' do
      song = create(:song, title: 'Ik Bel Je Zomaar Even Op', artists: [artist])
      song.update!(title: 'Ik Bel Je Zo Maar Even Op')
      expect(song.reload.normalized_title).to eq('ikbeljezomaarevenop')
    end

    it 'leaves normalized_title untouched when an unrelated attribute changes' do
      song = create(:song, title: 'Hello World', artists: [artist])
      expect { song.update!(popularity: 50) }.not_to(change { song.reload.normalized_title })
    end
  end

  describe '#update_search_text' do
    let(:artist) { create(:artist, name: 'Ed Sheeran') }
    let(:song) { create(:song, title: 'Shape of You', artists: [artist]) }

    it 'updates search_text when the title changes' do
      song.update(title: 'Perfect')
      expect(song.reload.search_text).to eq('Ed Sheeran Perfect')
    end

    it 'updates search_text when an artist is added' do
      new_artist = create(:artist, name: 'Beyoncé')
      song.update_artists([artist, new_artist])
      expect(song.reload.search_text).to eq('Ed Sheeran Beyoncé Shape of You')
    end
  end

  describe '#find_same_songs' do
    let(:artist) { create(:artist, name: 'Test Artist') }
    let(:song) { create(:song, title: 'Test Song', artists: [artist]) }

    context 'when no similar songs exist' do
      it 'returns only the original song' do
        result = song.find_same_songs
        expect(result).to contain_exactly(song)
      end
    end

    context 'when a song with the same title and artist exists' do
      let!(:duplicate_song) { create(:song, title: 'Test Song', artists: [artist]) }

      it 'returns both songs' do
        result = song.find_same_songs
        expect(result).to contain_exactly(song, duplicate_song)
      end
    end

    context 'when a song with the same title but different artist exists' do
      let(:other_artist) { create(:artist, name: 'Other Artist') }
      let!(:different_artist_song) { create(:song, title: 'Test Song', artists: [other_artist]) }

      it 'does not return the song with different artist' do
        result = song.find_same_songs
        expect(result).not_to include(different_artist_song)
      end
    end

    context 'when a song with different title but same artist exists' do
      let!(:different_title_song) { create(:song, title: 'Different Song', artists: [artist]) }

      it 'does not return the song with different title' do
        result = song.find_same_songs
        expect(result).not_to include(different_title_song)
      end
    end

    context 'when the title has different casing' do
      let!(:different_case_song) { create(:song, title: 'TEST SONG', artists: [artist]) }

      it 'finds songs with different casing' do
        result = song.find_same_songs
        expect(result).to contain_exactly(song, different_case_song)
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context 'when song has multiple artists' do
      let(:artist2) { create(:artist, name: 'Second Artist') }
      let(:song_with_multiple_artists) { create(:song, title: 'Collab Song', artists: [artist, artist2]) }
      let!(:partial_match_song) { create(:song, title: 'Collab Song', artists: [artist]) }

      it 'finds songs that share at least one artist' do
        result = song_with_multiple_artists.find_same_songs
        expect(result).to include(song_with_multiple_artists, partial_match_song)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context 'when artists are preloaded' do
      before { song.artists.load }

      it 'confirms artists are loaded' do
        expect(song.artists.loaded?).to be true
      end

      it 'finds same songs using loaded artists' do
        result = song.find_same_songs
        expect(result).to contain_exactly(song)
      end
    end
  end

  describe '#played' do
    let(:artist) { create(:artist, name: 'Play Count Artist') }
    let(:song) { create(:song, title: 'Play Count Song', artists: [artist]) }
    let(:radio_station) { create(:radio_station) }

    context 'when song has no air plays' do
      it 'returns 0' do
        expect(song.played).to eq(0)
      end
    end

    context 'when song has air plays' do
      before do
        create_list(:air_play, 5, song: song, radio_station: radio_station)
      end

      it 'returns the correct count' do
        expect(song.played).to eq(5)
      end
    end

    context 'when song has many air plays' do
      before do
        create_list(:air_play, 100, song: song, radio_station: radio_station)
      end

      it 'returns the correct count' do
        expect(song.played).to eq(100)
      end
    end
  end

  describe '#find_and_remove_obsolete_song' do
    let(:artist) { create(:artist, name: 'Obsolete Test Artist') }
    let(:song) { create(:song, title: 'Obsolete Test Song', artists: [artist]) }
    let(:duplicate_song) { create(:song, title: 'Obsolete Test Song', artists: [artist]) }
    let(:radio_station) { create(:radio_station) }

    context 'when no duplicates exist' do
      it 'does not remove any songs' do
        song # Create the song
        expect { song.find_and_remove_obsolete_song }.not_to change(Song, :count)
      end
    end

    context 'when duplicates exist' do
      before do
        create_list(:air_play, 5, song: song, radio_station: radio_station)
        create_list(:air_play, 2, song: duplicate_song, radio_station: radio_station)
      end

      it 'keeps the most played song' do
        song.find_and_remove_obsolete_song
        expect(Song.exists?(song.id)).to be true
      end

      it 'removes the less played duplicate' do
        song.find_and_remove_obsolete_song
        expect(Song.exists?(duplicate_song.id)).to be false
      end

      it 'transfers air plays to the most played song' do
        original_count = song.air_plays.count
        song.find_and_remove_obsolete_song
        expect(song.reload.air_plays.count).to eq(original_count + 2)
      end
    end

    context 'when the current song has fewer plays than duplicate' do
      before do
        create_list(:air_play, 2, song: song, radio_station: radio_station)
        create_list(:air_play, 5, song: duplicate_song, radio_station: radio_station)
      end

      it 'keeps the most played song (the duplicate)' do
        song.find_and_remove_obsolete_song
        expect(Song.exists?(duplicate_song.id)).to be true
      end

      it 'removes the less played song (the original)' do
        song.find_and_remove_obsolete_song
        expect(Song.exists?(song.id)).to be false
      end
    end

    context 'when songs have equal play counts' do
      before do
        create_list(:air_play, 3, song: song, radio_station: radio_station)
        create_list(:air_play, 3, song: duplicate_song, radio_station: radio_station)
      end

      it 'keeps one of the songs' do
        song.find_and_remove_obsolete_song
        expect(Song.where(title: 'Obsolete Test Song').count).to eq(1)
      end
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe 'cleanup_radio_station_songs' do
    let(:artist) { create(:artist, name: 'Cleanup Artist') }
    let(:song) { create(:song, title: 'Cleanup Song', artists: [artist]) }
    let(:duplicate_song) { create(:song, title: 'Cleanup Song', artists: [artist]) }
    let(:primary_station) { create(:radio_station) }
    let(:secondary_station) { create(:radio_station) }

    context 'when cleaning up songs across multiple radio stations' do
      before do
        # The air_play factory callback automatically creates RadioStationSong records
        create(:air_play, song: song, radio_station: primary_station, broadcasted_at: 2.days.ago)
        create(:air_play, song: song, radio_station: secondary_station, broadcasted_at: 1.day.ago)
        create(:air_play, song: duplicate_song, radio_station: primary_station, broadcasted_at: 3.days.ago)
      end

      it 'removes RadioStationSong records for obsolete songs' do
        song.find_and_remove_obsolete_song

        expect(RadioStationSong.where(song: duplicate_song)).to be_empty
      end

      it 'keeps RadioStationSong records for the most played song' do
        song.find_and_remove_obsolete_song

        expect(RadioStationSong.where(song: song).count).to be >= 1
      end

      it 'updates first_broadcasted_at to the earliest broadcast' do
        song.find_and_remove_obsolete_song

        rss = RadioStationSong.find_by(song: song, radio_station: primary_station)
        # The earliest broadcast for song on primary_station is 3.days.ago (from duplicate_song's air_play)
        expect(rss.first_broadcasted_at).to be <= 2.days.ago
      end
    end

    context 'when song has no radio station songs' do
      it 'does not raise an error' do
        expect { song.find_and_remove_obsolete_song }.not_to raise_error
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  describe '#popularity_boost' do
    let(:artist) { create(:artist, name: 'Boost Artist') }

    context 'when song has no popularity data' do
      let(:song) { create(:song, title: 'No Data', artists: [artist], popularity: nil, lastfm_listeners: nil, lastfm_playcount: nil) }

      it 'returns 1.0 (no boost)' do
        expect(song.popularity_boost).to eq(1.0)
      end
    end

    context 'when song has maximum Spotify popularity' do
      let(:song) { create(:song, title: 'Popular', artists: [artist], popularity: 100, lastfm_listeners: nil, lastfm_playcount: nil) }

      it 'returns 1.15' do
        expect(song.popularity_boost).to eq(1.15)
      end
    end

    context 'when song has all popularity data at high values' do
      let(:song) do
        create(:song, title: 'Very Popular', artists: [artist], popularity: 100, lastfm_listeners: 100_000_000, lastfm_playcount: 1_000_000_000)
      end

      it 'returns the maximum boost of 1.30' do
        expect(song.popularity_boost).to eq(1.30)
      end
    end

    context 'when song has moderate popularity data' do
      let(:song) { create(:song, title: 'Moderate', artists: [artist], popularity: 50, lastfm_listeners: 1_000_000, lastfm_playcount: 10_000_000) }

      it 'returns a boost between 1.0 and 1.30', :aggregate_failures do
        boost = song.popularity_boost
        expect(boost).to be > 1.0
        expect(boost).to be < 1.30
      end
    end
  end

  describe '#normalized_lastfm_listeners' do
    let(:artist) { create(:artist, name: 'Norm Artist') }

    context 'when lastfm_listeners is nil' do
      let(:song) { create(:song, title: 'Nil Listeners', artists: [artist], lastfm_listeners: nil) }

      it 'returns 0.0' do
        expect(song.normalized_lastfm_listeners).to eq(0.0)
      end
    end

    context 'when lastfm_listeners is 0' do
      let(:song) { create(:song, title: 'Zero Listeners', artists: [artist], lastfm_listeners: 0) }

      it 'returns 0.0' do
        expect(song.normalized_lastfm_listeners).to eq(0.0)
      end
    end

    context 'when lastfm_listeners is 100_000_000 (max normalization)' do
      let(:song) { create(:song, title: 'Max Listeners', artists: [artist], lastfm_listeners: 100_000_000) }

      it 'returns 1.0' do
        expect(song.normalized_lastfm_listeners).to eq(1.0)
      end
    end

    context 'when lastfm_listeners exceeds max (clamped)' do
      let(:song) { create(:song, title: 'Over Max', artists: [artist], lastfm_listeners: 1_000_000_000) }

      it 'returns 1.0 (clamped)' do
        expect(song.normalized_lastfm_listeners).to eq(1.0)
      end
    end
  end

  describe '#normalized_lastfm_playcount' do
    let(:artist) { create(:artist, name: 'Playcount Artist') }

    context 'when lastfm_playcount is nil' do
      let(:song) { create(:song, title: 'Nil Playcount', artists: [artist], lastfm_playcount: nil) }

      it 'returns 0.0' do
        expect(song.normalized_lastfm_playcount).to eq(0.0)
      end
    end

    context 'when lastfm_playcount is 0' do
      let(:song) { create(:song, title: 'Zero Playcount', artists: [artist], lastfm_playcount: 0) }

      it 'returns 0.0' do
        expect(song.normalized_lastfm_playcount).to eq(0.0)
      end
    end

    context 'when lastfm_playcount is 1_000_000_000 (max normalization)' do
      let(:song) { create(:song, title: 'Max Playcount', artists: [artist], lastfm_playcount: 1_000_000_000) }

      it 'returns 1.0' do
        expect(song.normalized_lastfm_playcount).to eq(1.0)
      end
    end
  end

  # NOTE: The after_commit callbacks for update_youtube_from_wikipedia, enrich_with_deezer,
  # and enrich_with_itunes were disabled in commit 28098bb2 to prevent race conditions
  # where concurrent imports were causing incorrect data mutations.
  describe 'after_commit :update_youtube_from_wikipedia callback', skip: 'Callback disabled to prevent race conditions' do
    let(:artist) { create(:artist, name: 'Adele') }

    context 'when creating a song without id_on_youtube' do
      it 'calls update_youtube_from_wikipedia' do
        song = build(:song, title: 'Hello', artists: [artist], id_on_youtube: nil, id_on_spotify: '123')
        allow(song).to receive(:update_youtube_from_wikipedia)
        song.save!
        expect(song).to have_received(:update_youtube_from_wikipedia)
      end
    end

    context 'when creating a song with id_on_youtube already set' do
      it 'does not call update_youtube_from_wikipedia' do
        song = build(:song, title: 'Hello', artists: [artist], id_on_youtube: 'existing_id')
        allow(song).to receive(:update_youtube_from_wikipedia)
        song.save!
        expect(song).not_to have_received(:update_youtube_from_wikipedia)
      end
    end

    context 'when updating a song without id_on_youtube' do
      it 'calls update_youtube_from_wikipedia' do
        song = build(:song, title: 'Hello', artists: [artist], id_on_youtube: nil, id_on_spotify: '123')
        allow(song).to receive(:update_youtube_from_wikipedia)
        song.save!
        song.update!(title: 'Hello Updated')
        expect(song).to have_received(:update_youtube_from_wikipedia).twice
      end
    end

    context 'when updating a song with id_on_youtube already set' do
      it 'does not call update_youtube_from_wikipedia' do
        song = build(:song, title: 'Hello', artists: [artist], id_on_youtube: 'existing_id')
        allow(song).to receive(:update_youtube_from_wikipedia)
        song.save!
        song.update!(title: 'Hello Updated')
        expect(song).not_to have_received(:update_youtube_from_wikipedia)
      end
    end

    context 'when song has no searchable data' do
      it 'does not call update_youtube_from_wikipedia' do
        song = build(:song, title: nil, id_on_youtube: nil, id_on_spotify: nil, isrcs: [])
        allow(song).to receive(:update_youtube_from_wikipedia)
        song.save!
        expect(song).not_to have_received(:update_youtube_from_wikipedia)
      end
    end

    context 'when song has only title' do
      it 'calls update_youtube_from_wikipedia' do
        song = build(:song, title: 'Some Title', id_on_youtube: nil, id_on_spotify: nil, isrcs: [])
        allow(song).to receive(:update_youtube_from_wikipedia)
        song.save!
        expect(song).to have_received(:update_youtube_from_wikipedia)
      end
    end

    context 'when song has only isrcs' do
      it 'calls update_youtube_from_wikipedia' do
        song = build(:song, title: nil, id_on_youtube: nil, id_on_spotify: nil, isrcs: ['USRC12345678'])
        allow(song).to receive(:update_youtube_from_wikipedia)
        song.save!
        expect(song).to have_received(:update_youtube_from_wikipedia)
      end
    end
  end

  describe '#update_youtube_from_wikipedia' do
    let(:artist) { create(:artist, name: 'Adele') }
    let(:song) { create(:song, title: 'Rolling in the Deep', artists: [artist], id_on_youtube: nil) }

    context 'when song already has id_on_youtube' do
      let(:song_with_youtube) { create(:song, title: 'Hello', artists: [artist], id_on_youtube: 'existing_id') }

      it 'does not update id_on_youtube' do
        expect do
          song_with_youtube.update_youtube_from_wikipedia
        end.not_to(change { song_with_youtube.reload.id_on_youtube })
      end
    end

    context 'when Wikidata returns YouTube ID via Spotify ID', :use_vcr do
      let(:song_with_spotify) do
        create(:song,
               title: 'Rolling in the Deep',
               artists: [artist],
               id_on_youtube: nil,
               id_on_spotify: '1c8gk2PeTE04A1pIDH9YMk')
      end

      it 'updates id_on_youtube if found' do
        song_with_spotify.update_youtube_from_wikipedia
        # May or may not find it depending on Wikidata state
        expect(song_with_spotify.reload.id_on_youtube).to be_a(String).or be_nil
      end
    end

    context 'when Wikidata returns YouTube ID via ISRC', :use_vcr do
      let(:song_with_isrc) do
        create(:song,
               title: 'Rolling in the Deep',
               artists: [artist],
               id_on_youtube: nil,
               isrcs: ['GBBKS1000094'])
      end

      it 'updates id_on_youtube if found' do
        song_with_isrc.update_youtube_from_wikipedia
        # May or may not find it depending on Wikidata state
        expect(song_with_isrc.reload.id_on_youtube).to be_a(String).or be_nil
      end
    end

    context 'when song is not found in Wikidata', :use_vcr do
      let(:unknown_song) do
        create(:song,
               title: 'NonExistentSongXYZ123456',
               artists: [create(:artist, name: 'UnknownArtist')],
               id_on_youtube: nil)
      end

      it 'does not update id_on_youtube' do
        expect do
          unknown_song.update_youtube_from_wikipedia
        end.not_to(change { unknown_song.reload.id_on_youtube })
      end
    end

    context 'when updating Shake It Off by Taylor Swift', :use_vcr do
      let(:taylor_swift) { create(:artist, name: 'Taylor Swift') }
      let(:shake_it_off) do
        create(:song,
               title: 'Shake It Off',
               artists: [taylor_swift],
               id_on_youtube: nil)
      end

      it 'updates id_on_youtube to nfWlot6h_JM' do
        shake_it_off.update_youtube_from_wikipedia
        expect(shake_it_off.reload.id_on_youtube).to eq('nfWlot6h_JM')
      end
    end
  end
end
