# frozen_string_literal: true

require 'rails_helper'

describe DuplicateSongMerger do
  subject(:merger) { described_class.new }

  let(:artist) { create(:artist, name: 'Taylor Swift', id_on_spotify: 'artist_spotify_1') }

  describe '#find_duplicates' do
    context 'when songs share the same Spotify ID and artists' do
      let!(:song_a) { create(:song, title: 'Love Story', id_on_spotify: 'spotify_song_1', artists: [artist]) }
      let!(:song_b) { create(:song, title: 'Love Story', id_on_spotify: 'spotify_song_1', artists: [artist]) }

      before do
        create(:air_play, song: song_a)
        create(:air_play, song: song_a)
      end

      it 'groups them as duplicates', :aggregate_failures do
        groups = merger.find_duplicates

        expect(groups.size).to eq(1)
        expect(groups.first[:keeper]).to eq(song_a)
        expect(groups.first[:duplicates]).to eq([song_b])
        expect(groups.first[:reason]).to include('Spotify ID')
      end
    end

    context 'when songs share Spotify ID but have different artists' do
      let(:other_artist) { create(:artist, name: 'Ed Sheeran') }

      before do
        create(:song, title: 'Love Story', id_on_spotify: 'spotify_song_1', artists: [artist])
        create(:song, title: 'Love Story', id_on_spotify: 'spotify_song_1', artists: [other_artist])
      end

      it 'does not group them' do
        expect(merger.find_duplicates).to be_empty
      end
    end

    context 'when songs have fuzzy matching titles and same artists' do
      let!(:song_a) { create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist]) }
      let!(:song_b) { create(:song, title: 'Love Storyy', id_on_spotify: nil, artists: [artist]) }

      before { create(:air_play, song: song_a) }

      it 'groups them as duplicates', :aggregate_failures do
        groups = merger.find_duplicates

        expect(groups.size).to eq(1)
        expect(groups.first[:keeper]).to eq(song_a)
        expect(groups.first[:duplicates]).to eq([song_b])
        expect(groups.first[:reason]).to eq('fuzzy title match')
      end
    end

    context 'when songs have same title but different artists' do
      let(:other_artist) { create(:artist, name: 'Ed Sheeran') }

      before do
        create(:song, title: 'Love Story', artists: [artist])
        create(:song, title: 'Love Story', artists: [other_artist])
      end

      it 'does not group them' do
        expect(merger.find_duplicates).to be_empty
      end
    end

    context 'when songs have different titles and same artists' do
      before do
        create(:song, title: 'Love Story', artists: [artist])
        create(:song, title: 'Shake It Off', artists: [artist])
      end

      it 'does not group them' do
        expect(merger.find_duplicates).to be_empty
      end
    end

    context 'when fuzzy-matched songs have different Spotify IDs' do
      before do
        create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist])
        create(:song, title: 'Love Storyy', id_on_spotify: 'spotify_2', artists: [artist])
      end

      it 'does not group them' do
        expect(merger.find_duplicates).to be_empty
      end
    end

    context 'when songs have numbered slug suffixes (slug duplicates)' do
      let(:other_artist) { create(:artist, name: 'Snelle') }
      let!(:song_a) do
        create(:song, title: 'Ik Zing', id_on_spotify: 'spotify_1', artists: [artist], slug: 'ik-zing-taylor-swift')
      end
      let!(:song_b) do
        create(:song, title: 'Ik Zing', id_on_spotify: nil, artists: [artist, other_artist],
                      slug: 'ik-zing-taylor-swift-2')
      end

      before { create(:air_play, song: song_a) }

      it 'groups them as slug duplicates', :aggregate_failures do
        groups = merger.find_duplicates

        slug_group = groups.find { |g| g[:reason] == 'slug duplicate' }
        expect(slug_group).to be_present
        expect(slug_group[:keeper]).to eq(song_a)
        expect(slug_group[:duplicates]).to eq([song_b])
      end
    end

    context 'when slug duplicates have conflicting Spotify IDs' do
      before do
        create(:song, title: 'Ik Zing', id_on_spotify: 'spotify_1', artists: [artist], slug: 'ik-zing-taylor-swift')
        create(:song, title: 'Ik Zing', id_on_spotify: 'spotify_2', artists: [artist],
                      slug: 'ik-zing-taylor-swift-2')
      end

      it 'does not group them' do
        groups = merger.find_duplicates
        slug_group = groups.find { |g| g[:reason] == 'slug duplicate' }

        expect(slug_group).to be_nil
      end
    end

    context 'when slug duplicates are already caught by another strategy' do
      before do
        create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist],
                      slug: 'love-story-taylor-swift')
        create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist],
                      slug: 'love-story-taylor-swift-2')
      end

      it 'does not create a duplicate group for slugs', :aggregate_failures do
        groups = merger.find_duplicates

        expect(groups.size).to eq(1)
        expect(groups.first[:reason]).to include('Spotify ID')
      end
    end
  end

  describe '#merge_all' do
    let!(:keeper) { create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist]) }
    let!(:duplicate) { create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist]) }

    before do
      create(:air_play, song: keeper)
      create(:air_play, song: keeper)
      create(:air_play, song: duplicate)
    end

    it 'merges duplicates and returns counts', :aggregate_failures do
      result = merger.merge_all

      expect(result[:merged]).to eq(1)
      expect(result[:deleted]).to eq(1)
      expect(Song.find_by(id: duplicate.id)).to be_nil
      expect(keeper.reload.air_plays.count).to eq(3)
    end
  end

  describe '#merge_song' do
    let!(:radio_station) { create(:radio_station) }
    let!(:keeper) do
      create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', id_on_youtube: nil, artists: [artist], popularity: 80)
    end
    let!(:duplicate) do
      create(:song, title: 'Love Story', id_on_spotify: nil, id_on_youtube: 'yt_123', artists: [artist],
                    release_date: Date.new(2008, 9, 12), popularity: 60)
    end

    it 'transfers air plays from source to target', :aggregate_failures do
      air_play = create(:air_play, song: duplicate, radio_station:)

      merger.merge_song(duplicate, keeper)

      expect(keeper.reload.air_plays).to include(air_play)
      expect(Song.find_by(id: duplicate.id)).to be_nil
    end

    it 'enriches the target with source metadata', :aggregate_failures do
      merger.merge_song(duplicate, keeper)

      keeper.reload
      expect(keeper.id_on_youtube).to eq('yt_123')
      expect(keeper.release_date).to eq(Date.new(2008, 9, 12))
      expect(keeper.id_on_spotify).to eq('spotify_1')
      expect(keeper.popularity).to eq(80)
    end

    it 'deduplicates air plays at the same time on the same station' do
      broadcasted_at = 1.hour.ago
      create(:air_play, song: keeper, radio_station:, broadcasted_at:)
      create(:air_play, song: duplicate, radio_station:, broadcasted_at:)

      merger.merge_song(duplicate, keeper)

      expect(keeper.reload.air_plays.count).to eq(1)
    end

    context 'with chart_positions' do
      let!(:chart) { create(:chart) }
      let!(:keeper_position) { create(:chart_position, positianable: keeper, chart:, position: 3, counts: 10) }
      let!(:duplicate_position) { create(:chart_position, positianable: duplicate, chart:, position: 1, counts: 5) }

      it 'keeps the better position and higher counts', :aggregate_failures do
        merger.merge_song(duplicate, keeper)

        keeper_position.reload
        expect(keeper_position.position).to eq(1)
        expect(keeper_position.counts).to eq(10)
        expect(ChartPosition.find_by(id: duplicate_position.id)).to be_nil
      end
    end

    context 'with radio_station_songs' do
      let!(:keeper_rss) { create(:radio_station_song, song: keeper, radio_station:, first_broadcasted_at: 1.week.ago) }

      before { create(:radio_station_song, song: duplicate, radio_station:, first_broadcasted_at: 2.weeks.ago) }

      it 'keeps the earliest first_broadcasted_at' do
        merger.merge_song(duplicate, keeper)

        expect(keeper_rss.reload.first_broadcasted_at).to be_within(1.second).of(2.weeks.ago)
      end
    end
  end

  describe 'keeper selection' do
    context 'when one song has a Spotify ID and the other does not' do
      let!(:with_spotify) { create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist]) }

      before { create(:song, title: 'Love Story', id_on_spotify: nil, artists: [artist]) }

      it 'prefers the song with Spotify ID as keeper' do
        groups = merger.find_duplicates

        expect(groups.first[:keeper]).to eq(with_spotify)
      end
    end

    context 'when both have Spotify IDs but one has more air plays' do
      let!(:fewer_plays) { create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist]) }
      let!(:more_plays) { create(:song, title: 'Love Story', id_on_spotify: 'spotify_1', artists: [artist]) }

      before do
        create(:air_play, song: more_plays)
        create(:air_play, song: more_plays)
        create(:air_play, song: fewer_plays)
      end

      it 'prefers the song with more air plays as keeper' do
        groups = merger.find_duplicates

        expect(groups.first[:keeper]).to eq(more_plays)
      end
    end
  end
end
