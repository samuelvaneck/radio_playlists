# frozen_string_literal: true

require 'rails_helper'

describe TrackScraper::SimoneApiProcessor, type: :service do
  subject(:last_played_song) { processor.last_played_song }

  let(:processor) { described_class.new(radio_station) }
  let(:radio_station) do
    RadioStation.find_by(name: 'Simone FM').presence || create(:simone_fm)
  end
  let(:now_playing) { { 'artist' => 'Sandra', 'title' => "(I'll never be) Maria Magdalena" } }

  describe '#last_played_song' do
    before do
      allow(processor).to receive(:fetch_now_playing).and_return(api_response)
    end

    context 'when the API response is valid' do
      let(:api_response) { now_playing }

      it 'returns true' do
        expect(last_played_song).to be true
      end

      it 'sets the artist name' do
        last_played_song
        expect(processor.artist_name).to eq('Sandra')
      end

      it 'sets the title' do
        last_played_song
        expect(processor.title).to eq("(I'll Never Be) Maria Magdalena")
      end

      it 'sets broadcasted_at to now when no recent log exists' do
        last_played_song
        expect(processor.broadcasted_at).to be_within(1.second).of(Time.zone.now)
      end

      it 'sets the raw response' do
        last_played_song
        expect(processor.raw_response).to eq(now_playing)
      end
    end

    context 'when the API response is blank' do
      let(:api_response) { nil }

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when the artist is missing' do
      let(:api_response) { { 'artist' => nil, 'title' => 'Foo' } }

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when the title is missing' do
      let(:api_response) { { 'artist' => 'Sandra', 'title' => '' } }

      it 'returns false' do
        expect(last_played_song).to be false
      end
    end

    context 'when the same song is already in a recent log' do
      let(:api_response) { now_playing }
      let(:earlier_broadcasted_at) { 3.minutes.ago }

      before do
        SongImportLog.create!(
          radio_station: radio_station,
          status: :success,
          import_source: :scraping,
          scraped_artist: 'Sandra',
          scraped_title: "(I'll Never Be) Maria Magdalena",
          broadcasted_at: earlier_broadcasted_at
        )
      end

      it 'reuses the prior log broadcasted_at so SongImporter dedupes' do
        last_played_song
        expect(processor.broadcasted_at).to be_within(1.second).of(earlier_broadcasted_at)
      end
    end

    context 'when the most recent log is a different song' do
      let(:api_response) { now_playing }

      before do
        SongImportLog.create!(
          radio_station: radio_station,
          status: :success,
          import_source: :scraping,
          scraped_artist: 'Pearl Jam',
          scraped_title: 'Black',
          broadcasted_at: 4.minutes.ago
        )
      end

      it 'mints a fresh broadcasted_at' do
        last_played_song
        expect(processor.broadcasted_at).to be_within(1.second).of(Time.zone.now)
      end
    end

    context 'when the same song last played outside the same-song window' do
      let(:api_response) { now_playing }

      before do
        SongImportLog.create!(
          radio_station: radio_station,
          status: :success,
          import_source: :scraping,
          scraped_artist: 'Sandra',
          scraped_title: "(I'll Never Be) Maria Magdalena",
          broadcasted_at: 30.minutes.ago,
          created_at: 30.minutes.ago
        )
      end

      it 'mints a fresh broadcasted_at for the new airplay' do
        last_played_song
        expect(processor.broadcasted_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end
end
