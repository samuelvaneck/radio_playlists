# == Schema Information
#
# Table name: artists
#
#  id                           :bigint           not null, primary key
#  aka_names                    :string           default([]), is an Array
#  aka_names_checked_at         :datetime
#  country_of_origin            :string           default([]), is an Array
#  country_of_origin_checked_at :datetime
#  deezer_artist_url            :string
#  deezer_artwork_url           :string
#  genres                       :string           default([]), is an Array
#  id_on_deezer                 :string
#  id_on_itunes                 :string
#  id_on_musicbrainz            :string
#  id_on_spotify                :string
#  id_on_tidal                  :string
#  image                        :string
#  instagram_url                :string
#  itunes_artist_url            :string
#  lastfm_enriched_at           :datetime
#  lastfm_listeners             :bigint
#  lastfm_playcount             :bigint
#  lastfm_tags                  :string           default([]), is an Array
#  name                         :string
#  slug                         :string
#  spotify_artist_url           :string
#  spotify_artwork_url          :string
#  spotify_followers_count      :integer
#  spotify_popularity           :integer
#  tidal_artist_url             :string
#  website_url                  :string
#  wikipedia_url                :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
# Indexes
#
#  index_artists_on_aka_names          (aka_names) USING gin
#  index_artists_on_id_on_deezer       (id_on_deezer)
#  index_artists_on_id_on_itunes       (id_on_itunes)
#  index_artists_on_id_on_musicbrainz  (id_on_musicbrainz) UNIQUE
#  index_artists_on_id_on_tidal        (id_on_tidal)
#  index_artists_on_name_trgm          (name) USING gin
#  index_artists_on_slug               (slug) UNIQUE
#

describe Artist do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:artist_three) { create :artist }
  let(:song_three) { create :song, artists: [artist_three] }
  let(:radio_station) { create :radio_station }
  let(:air_play_one) { create :air_play, song: song_one }
  let(:air_play_two) { create :air_play, song: song_two, radio_station: }
  let(:air_play_three) { create :air_play, song: song_three, radio_station: }
  let(:air_play_four) { create :air_play, song: song_three, radio_station: }

  before do
    air_play_one
    air_play_two
    air_play_three
    air_play_four
  end

  describe '#search' do
    context 'with search term params present' do
      it 'only returns the artists matching the search term' do
        results = Artist.most_played({ search_term: artist_one.name })

        expect(results).to include artist_one
      end
    end

    context 'with radio_station_id params present' do
      it 'only returns the artists played on the radio_station' do
        results = Artist.most_played({ radio_station_id: radio_station.id })

        expect(results).to include artist_two, artist_three
      end
    end
  end

  describe '.faceted_search' do
    let!(:coldplay) { create(:artist, name: 'Coldplay', genres: %w[rock pop], country_of_origin: ['United Kingdom'], spotify_popularity: 90) }
    let!(:drake) { create(:artist, name: 'Drake', genres: %w[hip-hop rap], country_of_origin: ['Canada'], spotify_popularity: 95) }

    it 'filters by name', :aggregate_failures do
      results = Artist.faceted_search(name: 'Coldplay')
      expect(results).to include(coldplay)
      expect(results).not_to include(drake)
    end

    it 'filters by genre', :aggregate_failures do
      results = Artist.faceted_search(genre: 'rock')
      expect(results).to include(coldplay)
      expect(results).not_to include(drake)
    end

    it 'filters by country', :aggregate_failures do
      results = Artist.faceted_search(country: 'Canada')
      expect(results).to include(drake)
      expect(results).not_to include(coldplay)
    end

    it 'combines multiple filters' do
      results = Artist.faceted_search(genre: 'rock', country: 'United Kingdom')
      expect(results).to contain_exactly(coldplay)
    end

    it 'returns all artists when no filters given' do
      results = Artist.faceted_search
      expect(results).to include(coldplay, drake)
    end

    it 'respects limit' do
      results = Artist.faceted_search(limit: 1)
      expect(results.length).to eq(1)
    end

    context 'with blank filter values' do
      it 'ignores blank genre' do
        results = Artist.faceted_search(genre: '')
        expect(results).to include(coldplay, drake)
      end
    end
  end

  describe '.suggest' do
    let(:coldplay) do
      create(:artist, name: 'Coldplay', genres: %w[rock pop],
                      country_of_origin: ['United Kingdom'], spotify_popularity: 90)
    end

    it 'suggests artist names matching query' do
      coldplay
      expect(Artist.suggest(field: 'name', query: 'Cold')).to include('Coldplay')
    end

    it 'suggests genres matching query' do
      coldplay
      expect(Artist.suggest(field: 'genre', query: 'ro')).to include('rock')
    end

    it 'suggests countries matching query' do
      coldplay
      expect(Artist.suggest(field: 'country', query: 'United')).to include('United Kingdom')
    end

    it 'returns available field names for unknown field' do
      expect(Artist.suggest(field: nil)).to eq(%w[name genre country])
    end
  end

  describe '.search_by_name' do
    let!(:coldplay) { create(:artist, name: 'Coldplay', spotify_popularity: 90) }

    it 'finds artists with exact match' do
      expect(Artist.search_by_name('Coldplay')).to include(coldplay)
    end

    it 'finds artists with typo in query' do
      expect(Artist.search_by_name('Coldpaly')).to include(coldplay)
    end

    it 'finds artists with prefix match' do
      expect(Artist.search_by_name('Coldp')).to include(coldplay)
    end

    it 'ranks more popular artists higher' do
      less_popular = create(:artist, name: 'Coldploy', spotify_popularity: 5)
      results = Artist.search_by_name('Coldplay')

      expect(results.index(coldplay)).to be < results.index(less_popular)
    end
  end

  describe '#cleanup' do
    context 'if the artist has no songs' do
      let!(:artist_no_songs) { create :artist }
      it 'destroys the artist' do
        expect {
          artist_no_songs.cleanup
        }.to change(Artist, :count).by(-1)
      end
    end

    context 'if the artist has songs' do
      it 'does not destroy the artist' do
        expect {
          artist_one.cleanup
        }.not_to change(Artist, :count)
      end
    end
  end

  describe 'TimeAnalyticsConcern' do
    let(:artist) { create(:artist) }
    let(:song) { create(:song, artists: [artist]) }
    let(:radio_station_one) { create(:radio_station) }
    let(:radio_station_two) { create(:radio_station) }

    describe '#peak_play_hours' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 0, 0))
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 30, 0))
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 14, 0, 0))
        create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: Time.utc(2024, 1, 15, 20, 0, 0))
      end

      it 'returns hour distribution with play counts', :aggregate_failures do
        result = artist.peak_play_hours
        expect(result[8]).to eq(2)
        expect(result[14]).to eq(1)
        expect(result[20]).to eq(1)
      end

      it 'orders by count descending' do
        result = artist.peak_play_hours
        expect(result.keys.first).to eq(8)
      end

      context 'with radio_station_ids filter' do
        it 'filters by radio station', :aggregate_failures do
          result = artist.peak_play_hours(radio_station_ids: [radio_station_one.id])
          expect(result[8]).to eq(2)
          expect(result[14]).to eq(1)
          expect(result[20]).to be_nil
        end
      end
    end

    describe '#peak_play_days' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 15, 10, 0, 0)) # Monday
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 15, 14, 0, 0)) # Monday
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.zone.local(2024, 1, 19, 10, 0, 0)) # Friday
        create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: Time.zone.local(2024, 1, 21, 10, 0, 0)) # Sunday
      end

      it 'returns day of week distribution with play counts', :aggregate_failures do
        result = artist.peak_play_days
        expect(result[1]).to eq(2) # Monday
        expect(result[5]).to eq(1) # Friday
        expect(result[0]).to eq(1) # Sunday
      end

      context 'with radio_station_ids filter' do
        it 'filters by radio station', :aggregate_failures do
          result = artist.peak_play_days(radio_station_ids: [radio_station_one.id])
          expect(result[1]).to eq(2) # Monday
          expect(result[5]).to eq(1) # Friday
          expect(result[0]).to be_nil # Sunday was on radio_station_two
        end
      end
    end

    describe '#peak_play_times_summary' do
      before do
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 0, 0))
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 15, 8, 30, 0))
        create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: Time.utc(2024, 1, 16, 14, 0, 0))
      end

      it 'returns a summary with peak hour and day', :aggregate_failures do
        result = artist.peak_play_times_summary
        expect(result[:peak_hour]).to eq(8)
        expect(result[:peak_day]).to eq(1) # Monday
        expect(result[:peak_day_name]).to eq('Monday')
      end

      it 'includes hourly distribution' do
        result = artist.peak_play_times_summary
        expect(result[:hourly_distribution][8]).to eq(2)
      end

      it 'includes daily distribution with day names' do
        result = artist.peak_play_times_summary
        expect(result[:daily_distribution]['Monday']).to eq(2)
      end
    end

    describe '#play_frequency_trend' do
      context 'with sufficient data' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 4.weeks.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.weeks.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 2.weeks.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 2.weeks.ago + 1.day)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago + 1.day)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.week.ago + 2.days)
        end

        it 'returns trend data' do
          result = artist.play_frequency_trend(weeks: 4)
          expect(result).to include(:trend, :trend_percentage, :weekly_counts, :first_period_avg, :second_period_avg)
        end

        it 'detects rising trend' do
          result = artist.play_frequency_trend(weeks: 4)
          expect(result[:trend]).to eq(:rising)
        end
      end

      context 'with insufficient data' do
        it 'returns nil when artist has no air plays' do
          new_artist = create(:artist)
          expect(new_artist.play_frequency_trend).to be_nil
        end
      end
    end

    describe '#lifecycle_stats' do
      context 'with air plays' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 30.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 20.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
          create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: 5.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.day.ago)
        end

        it 'returns first and last play dates', :aggregate_failures do
          result = artist.lifecycle_stats
          expect(result[:first_play]).to be_within(1.minute).of(30.days.ago)
          expect(result[:last_play]).to be_within(1.minute).of(1.day.ago)
        end

        it 'returns total plays' do
          result = artist.lifecycle_stats
          expect(result[:total_plays]).to eq(5)
        end

        it 'returns days active' do
          result = artist.lifecycle_stats
          expect(result[:days_active]).to eq(30)
        end
      end

      context 'with no air plays' do
        it 'returns nil' do
          new_artist = create(:artist)
          expect(new_artist.lifecycle_stats).to be_nil
        end
      end

      context 'with radio_station_ids filter' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 5.days.ago)
          create(:air_play, song: song, radio_station: radio_station_two, broadcasted_at: 1.day.ago)
        end

        it 'filters by radio station', :aggregate_failures do
          result_all = artist.lifecycle_stats
          result_filtered = artist.lifecycle_stats(radio_station_ids: [radio_station_one.id])

          expect(result_all[:total_plays]).to eq(3)
          expect(result_filtered[:total_plays]).to eq(2)
        end
      end
    end

    describe '#days_on_air' do
      context 'with air plays' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 1.day.ago)
        end

        it 'returns the number of days between first and last play' do
          expect(artist.days_on_air).to eq(10)
        end
      end

      context 'with no air plays' do
        it 'returns 0' do
          new_artist = create(:artist)
          expect(new_artist.days_on_air).to eq(0)
        end
      end
    end

    describe '#still_playing?' do
      context 'with recent air play' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 3.days.ago)
        end

        it 'returns true when played within default 7 days' do
          expect(artist.still_playing?).to be true
        end

        it 'returns false when not played within custom days' do
          expect(artist.still_playing?(within_days: 2)).to be false
        end
      end

      context 'with no air plays' do
        it 'returns false' do
          new_artist = create(:artist)
          expect(new_artist.still_playing?).to be false
        end
      end
    end

    describe '#dormant?' do
      context 'with recent air play' do
        before do
          create(:air_play, song: song, radio_station: radio_station_one, broadcasted_at: 10.days.ago)
        end

        it 'returns false when played within default 30 days' do
          expect(artist.dormant?).to be false
        end

        it 'returns true when not played within custom days' do
          expect(artist.dormant?(inactive_days: 5)).to be true
        end
      end

      context 'with no air plays' do
        it 'returns true' do
          new_artist = create(:artist)
          expect(new_artist.dormant?).to be true
        end
      end
    end
  end

  describe '#similar_artists' do
    let(:artist) { create(:artist, name: 'Coldplay', genres: %w[rock pop britpop], lastfm_tags: %w[rock british alternative]) }

    context 'when matching only on genres' do
      let!(:genre_match) { create(:artist, name: 'Muse', genres: %w[rock alternative], lastfm_tags: %w[space-rock]) }

      it 'returns artists with overlapping genres' do
        results = artist.similar_artists
        expect(results).to include(genre_match)
      end
    end

    context 'when matching only on lastfm_tags' do
      let!(:tag_match) { create(:artist, name: 'Radiohead', genres: %w[art-rock], lastfm_tags: %w[british alternative]) }

      it 'returns artists with overlapping tags' do
        results = artist.similar_artists
        expect(results).to include(tag_match)
      end
    end

    context 'when breaking ties with spotify_popularity' do
      let!(:popular) { create(:artist, name: 'U2', genres: %w[rock], lastfm_tags: [], spotify_popularity: 90) }
      let!(:unpopular) { create(:artist, name: 'Indie Band', genres: %w[rock], lastfm_tags: [], spotify_popularity: 10) }

      it 'ranks more popular artist first among equal similarity scores', :aggregate_failures do
        results = artist.similar_artists
        expect(results.index(popular)).to be < results.index(unpopular)
      end
    end

    context 'when the artist has no genres or tags' do
      let(:empty_artist) { create(:artist, name: 'Unknown', genres: [], lastfm_tags: []) }

      it 'returns an empty relation' do
        expect(empty_artist.similar_artists).to be_empty
      end
    end

    context 'when the artist has tags but no genres' do
      let(:tags_only_artist) { create(:artist, name: 'Taylor Swift', genres: [], lastfm_tags: %w[pop country]) }
      let!(:tag_match) { create(:artist, name: 'Kacey Musgraves', genres: %w[country], lastfm_tags: %w[country americana]) }

      it 'returns artists matching on tags' do
        results = tags_only_artist.similar_artists
        expect(results).to include(tag_match)
      end
    end

    it 'excludes the artist itself' do
      create(:artist, name: 'Clone', genres: %w[rock pop britpop], lastfm_tags: %w[rock british alternative])
      results = artist.similar_artists
      expect(results).not_to include(artist)
    end

    it 'excludes artists with no overlap' do
      no_overlap = create(:artist, name: 'Eminem', genres: %w[hip-hop rap], lastfm_tags: %w[rap hip-hop])
      results = artist.similar_artists
      expect(results).not_to include(no_overlap)
    end

    it 'respects the limit parameter' do
      15.times { |i| create(:artist, name: "Band #{i}", genres: %w[rock], lastfm_tags: []) }
      results = artist.similar_artists(limit: 5)
      expect(results.size).to eq(5)
    end

    context 'when tags contain special characters' do
      let!(:special) { create(:artist, name: "Destiny's Child", genres: %w[r&b pop], lastfm_tags: %w[rnb]) }
      let(:artist_with_special) { create(:artist, name: 'Beyonce', genres: %w[r&b pop], lastfm_tags: %w[rnb soul]) }

      it 'handles special characters safely' do
        results = artist_with_special.similar_artists
        expect(results).to include(special)
      end
    end

    context 'when ordering by similarity with popularity tiebreaker' do
      let!(:low_similarity_popular) do
        create(:artist, name: 'Jay-Z', genres: %w[pop], lastfm_tags: [], spotify_popularity: 95)
      end
      let!(:high_similarity_unpopular) do
        create(:artist, name: 'Oasis', genres: %w[rock britpop], lastfm_tags: %w[rock british], spotify_popularity: 50)
      end

      it 'ranks higher similarity above higher popularity', :aggregate_failures do
        results = artist.similar_artists
        expect(results.index(high_similarity_unpopular)).to be < results.index(low_similarity_popular)
      end
    end
  end

  describe '#update_website_from_wikipedia' do
    context 'when artist has no website_url', :use_vcr do
      let(:artist) { create(:artist, name: 'Coldplay', website_url: nil) }

      it 'updates the website_url from Wikipedia' do
        artist.update_website_from_wikipedia
        expect(artist.reload.website_url).to include('coldplay')
      end
    end

    context 'when artist already has a website_url' do
      let(:artist) { create(:artist, name: 'Coldplay', website_url: 'https://existing.com') }

      it 'does not update the website_url' do
        artist.update_website_from_wikipedia
        expect(artist.reload.website_url).to eq('https://existing.com')
      end
    end

    context 'when artist is not found on Wikipedia', :use_vcr do
      let(:artist) { create(:artist, name: 'NonExistentArtistXYZ123456', website_url: nil) }

      it 'does not update the website_url' do
        artist.update_website_from_wikipedia
        expect(artist.reload.website_url).to be_nil
      end
    end
  end

  describe '#fetch_aka_names' do
    let(:artist) { create(:artist, name: 'P!nk') }
    let(:fetcher) { instance_double(MusicBrainz::ArtistAliasFetcher, call: true) }

    before { allow(MusicBrainz::ArtistAliasFetcher).to receive(:new).with(artist).and_return(fetcher) }

    it 'delegates to MusicBrainz::ArtistAliasFetcher', :aggregate_failures do
      artist.fetch_aka_names
      expect(MusicBrainz::ArtistAliasFetcher).to have_received(:new).with(artist)
      expect(fetcher).to have_received(:call)
    end
  end
end
