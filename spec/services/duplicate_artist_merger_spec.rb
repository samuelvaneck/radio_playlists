# frozen_string_literal: true

require 'rails_helper'

describe DuplicateArtistMerger do
  subject(:merger) { described_class.new }

  describe '#find_duplicates' do
    context 'when artists share the same Spotify ID' do
      let!(:artist_a) { create(:artist, name: 'Taylor Swift', id_on_spotify: 'spotify123') }
      let!(:artist_b) { create(:artist, name: 'Taylor Swift', id_on_spotify: 'spotify123') }

      before { create(:song, artists: [artist_a]) }

      it 'groups them as duplicates', :aggregate_failures do
        groups = merger.find_duplicates

        expect(groups.size).to eq(1)
        expect(groups.first[:keeper]).to eq(artist_a)
        expect(groups.first[:duplicates]).to eq([artist_b])
        expect(groups.first[:reason]).to include('Spotify ID')
      end
    end

    context 'when artist names are reversed (Last, First)' do
      let!(:artist_a) { create(:artist, name: 'Taylor Swift', id_on_spotify: 'spotify123') }
      let!(:artist_b) { create(:artist, name: 'Swift, Taylor', id_on_spotify: nil) }

      before { create(:song, artists: [artist_a]) }

      it 'groups them as duplicates', :aggregate_failures do
        groups = merger.find_duplicates

        expect(groups.size).to eq(1)
        expect(groups.first[:keeper]).to eq(artist_a)
        expect(groups.first[:duplicates]).to eq([artist_b])
        expect(groups.first[:reason]).to eq('fuzzy name match')
      end
    end

    context 'when artist names have slight variations' do
      let!(:artist_a) { create(:artist, name: 'David Guetta', id_on_spotify: 'spotify456') }
      let!(:artist_b) { create(:artist, name: 'David Gueta', id_on_spotify: nil) }

      before { create(:song, artists: [artist_a]) }

      it 'groups them as duplicates', :aggregate_failures do
        groups = merger.find_duplicates

        expect(groups.size).to eq(1)
        expect(groups.first[:keeper]).to eq(artist_a)
        expect(groups.first[:duplicates]).to include(artist_b)
      end
    end

    context 'when artists are completely different' do
      before do
        create(:artist, name: 'Taylor Swift')
        create(:artist, name: 'David Guetta')
      end

      it 'does not group them' do
        groups = merger.find_duplicates

        expect(groups).to be_empty
      end
    end

    context 'when fuzzy-matched artists have different Spotify IDs' do
      before do
        create(:artist, name: 'Paul Simon', id_on_spotify: 'spotify_paul_simon')
        create(:artist, name: 'Paul Simonon', id_on_spotify: 'spotify_paul_simonon')
      end

      it 'does not group them' do
        groups = merger.find_duplicates

        expect(groups).to be_empty
      end
    end

    context 'when fuzzy-matched artist has no Spotify ID' do
      let!(:with_spotify) { create(:artist, name: 'David Guetta', id_on_spotify: 'spotify456') }
      let!(:without_spotify) { create(:artist, name: 'David Gueta', id_on_spotify: nil) }

      before { create(:song, artists: [with_spotify]) }

      it 'groups the one without Spotify ID as duplicate' do
        groups = merger.find_duplicates

        expect(groups.first[:duplicates]).to eq([without_spotify])
      end
    end

    context 'when no duplicates exist' do
      before { create(:artist, name: 'Unique Artist') }

      it 'returns empty array' do
        expect(merger.find_duplicates).to be_empty
      end
    end
  end

  describe '#merge_all' do
    context 'when there are duplicates to merge' do
      let!(:keeper) { create(:artist, name: 'David Guetta', id_on_spotify: 'spotify456', spotify_popularity: 90) }
      let!(:duplicate) { create(:artist, name: 'David Guetta', id_on_spotify: 'spotify456', spotify_popularity: 50) }
      let!(:keeper_song) { create(:song, artists: [keeper]) }
      let!(:duplicate_song) { create(:song, artists: [duplicate]) }

      it 'merges duplicates and returns counts', :aggregate_failures do
        result = merger.merge_all

        expect(result[:merged]).to eq(1)
        expect(result[:deleted]).to eq(1)
        expect(Artist.find_by(id: duplicate.id)).to be_nil
        expect(keeper.reload.songs).to include(keeper_song, duplicate_song)
      end
    end

    context 'when there are no duplicates' do
      before { create(:artist, name: 'Unique Artist') }

      it 'returns zero counts' do
        expect(merger.merge_all).to eq({ merged: 0, deleted: 0 })
      end
    end
  end

  describe '#merge_artist' do
    let!(:keeper) { create(:artist, name: 'Taylor Swift', id_on_spotify: 'spotify123', genres: ['pop']) }
    let!(:duplicate) { create(:artist, name: 'Swift, Taylor', id_on_spotify: nil, genres: ['country'], website_url: 'https://taylorswift.com') }
    let!(:song_a) { create(:song, artists: [keeper]) }
    let!(:song_b) { create(:song, artists: [duplicate]) }
    let!(:shared_song) { create(:song, artists: [keeper, duplicate]) }

    it 'reassigns songs from source to target', :aggregate_failures do
      merger.merge_artist(duplicate, keeper)

      expect(keeper.reload.songs).to include(song_a, song_b, shared_song)
      expect(Artist.find_by(id: duplicate.id)).to be_nil
    end

    context 'with air plays on duplicate artist songs' do
      let!(:air_play_a) { create(:air_play, song: song_a) }
      let!(:air_play_b) { create(:air_play, song: song_b) }

      it 'makes air plays accessible through the keeper', :aggregate_failures do
        merger.merge_artist(duplicate, keeper)

        expect(keeper.reload.air_plays).to include(air_play_a, air_play_b)
        expect(air_play_b.reload.song).to eq(song_b)
      end
    end

    it 'enriches the target with source metadata', :aggregate_failures do
      merger.merge_artist(duplicate, keeper)

      keeper.reload
      expect(keeper.genres).to match_array(%w[pop country])
      expect(keeper.website_url).to eq('https://taylorswift.com')
      expect(keeper.id_on_spotify).to eq('spotify123')
    end

    context 'with chart_positions' do
      let!(:chart) { create(:chart) }
      let!(:keeper_position) { create(:chart_position, positianable: keeper, chart:, position: 3, counts: 10) }
      let!(:duplicate_position) { create(:chart_position, positianable: duplicate, chart:, position: 1, counts: 5) }

      it 'keeps the better position and higher counts', :aggregate_failures do
        merger.merge_artist(duplicate, keeper)

        keeper_position.reload
        expect(keeper_position.position).to eq(1)
        expect(keeper_position.counts).to eq(10)
        expect(ChartPosition.find_by(id: duplicate_position.id)).to be_nil
      end
    end

    context 'with chart_positions only on source' do
      let!(:chart) { create(:chart) }
      let!(:duplicate_position) { create(:chart_position, positianable: duplicate, chart:, position: 5, counts: 8) }

      it 'transfers the chart position to keeper' do
        merger.merge_artist(duplicate, keeper)

        duplicate_position.reload
        expect(duplicate_position.positianable).to eq(keeper)
      end
    end
  end

  describe 'keeper selection' do
    context 'when one artist has a Spotify ID and the other does not' do
      let!(:with_spotify) { create(:artist, name: 'Taylor Swift', id_on_spotify: 'spotify123') }
      let!(:without_spotify) { create(:artist, name: 'Swift, Taylor', id_on_spotify: nil) }

      before { create(:song, artists: [without_spotify]) }

      it 'prefers the artist with Spotify ID as keeper' do
        groups = merger.find_duplicates

        expect(groups.first[:keeper]).to eq(with_spotify)
      end
    end

    context 'when both have Spotify IDs but one has more songs' do
      let!(:fewer_songs) { create(:artist, name: 'David Guetta', id_on_spotify: 'spotify456') }
      let!(:more_songs) { create(:artist, name: 'David Guetta', id_on_spotify: 'spotify456') }

      before do
        create(:song, artists: [more_songs])
        create(:song, artists: [more_songs])
        create(:song, artists: [fewer_songs])
      end

      it 'prefers the artist with more songs as keeper' do
        groups = merger.find_duplicates

        expect(groups.first[:keeper]).to eq(more_songs)
      end
    end
  end
end
