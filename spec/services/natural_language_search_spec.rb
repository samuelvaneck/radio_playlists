# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NaturalLanguageSearch, type: :service do
  let(:query) { 'upbeat Dutch songs played on Radio 538 last week' }
  let(:service) { described_class.new(query) }
  let(:radio_station) { create(:radio_station, name: 'Radio 538') }
  let(:dutch_artist) { create(:artist, name: 'Davina Michelle', country_of_origin: ['NL'], genres: ['pop']) }
  let(:song) { create(:song, title: 'Duurt Te Lang', artists: [dutch_artist], popularity: 80) }
  let(:translator) { instance_double(Llm::QueryTranslator) }

  before do
    create(:music_profile, song: song, valence: 0.8, energy: 0.8)
    create(:air_play, song: song, radio_station: radio_station, broadcasted_at: 2.days.ago, status: :confirmed)
    allow(Llm::QueryTranslator).to receive(:new).and_return(translator)
  end

  describe '#search' do
    subject(:search) { service.search }

    context 'when the translator returns song filters' do
      before do
        allow(translator).to receive(:translate).and_return(
          country: 'NL',
          radio_station: 'Radio 538',
          period: 'week',
          mood: 'upbeat'
        )
      end

      it 'returns an ActiveRecord relation' do
        expect(search).to be_a(ActiveRecord::Relation)
      end

      it 'includes songs matching the filters' do
        expect(search.map(&:id)).to include(song.id)
      end
    end

    context 'when the translator returns artist search type' do
      let(:artist_query) { 'popular Dutch pop artists' }
      let(:artist_service) { described_class.new(artist_query) }

      before do
        allow(translator).to receive(:translate).and_return(
          search_type: 'artists',
          country: 'NL',
          genre: 'pop',
          period: 'month'
        )
      end

      it 'returns artists matching the filters' do
        results = artist_service.search
        expect(results.map(&:id)).to include(dutch_artist.id)
      end
    end

    context 'when the translator returns empty filters' do
      before do
        allow(translator).to receive(:translate).and_return({})
      end

      it 'returns an empty relation' do
        expect(search).to be_empty
      end
    end

    context 'when filtering by radio station name' do
      before do
        allow(translator).to receive(:translate).and_return(
          radio_station: 'Radio 538',
          period: 'week'
        )
      end

      it 'resolves the station by name and filters results' do
        expect(search.map(&:id)).to include(song.id)
      end
    end

    context 'when filtering by year range' do
      let(:old_song) { create(:song, title: 'Old Song', release_date: Date.new(2010, 1, 1)) }
      let(:new_song) { create(:song, title: 'New Song', release_date: Date.new(2024, 6, 1)) }

      before do
        create(:air_play, song: old_song, radio_station: radio_station, broadcasted_at: 1.day.ago, status: :confirmed)
        create(:air_play, song: new_song, radio_station: radio_station, broadcasted_at: 1.day.ago, status: :confirmed)
        allow(translator).to receive(:translate).and_return(
          year_from: 2020,
          period: 'week'
        )
      end

      it 'filters songs by release year', :aggregate_failures do
        result_ids = search.map(&:id)
        expect(result_ids).to include(new_song.id)
        expect(result_ids).not_to include(old_song.id)
      end
    end

    context 'when sorting by popularity' do
      let(:popular_song) { create(:song, title: 'Hit Song', popularity: 95) }
      let(:unpopular_song) { create(:song, title: 'Unknown Song', popularity: 10) }

      before do
        create(:air_play, song: popular_song, radio_station: radio_station, broadcasted_at: 1.day.ago,
                          status: :confirmed)
        create(:air_play, song: unpopular_song, radio_station: radio_station, broadcasted_at: 1.day.ago,
                          status: :confirmed)
        allow(translator).to receive(:translate).and_return(
          sort_by: 'popularity',
          period: 'week'
        )
      end

      it 'returns songs ordered by popularity' do
        result_ids = search.map(&:id)
        popular_idx = result_ids.index(popular_song.id)
        unpopular_idx = result_ids.index(unpopular_song.id)
        expect(popular_idx).to be < unpopular_idx
      end
    end
  end

  describe '#filters' do
    before do
      allow(translator).to receive(:translate).and_return(
        country: 'NL',
        period: 'week'
      )
    end

    it 'exposes the parsed filters after search' do
      service.search
      expect(service.filters).to eq(country: 'NL', period: 'week')
    end
  end
end
