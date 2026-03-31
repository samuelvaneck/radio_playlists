# frozen_string_literal: true

require 'rails_helper'

describe BulkImportSongsJob do
  describe '#perform' do
    let(:radio_station) { create(:decibel) }
    let(:processor) { instance_double(TrackScraper::MytunerApiProcessor) }
    let(:played_songs) do
      [
        PlayedSong.new(artist_name: 'Artist One', title: 'Song One', broadcasted_at: 2.hours.ago),
        PlayedSong.new(artist_name: 'Artist Two', title: 'Song Two', broadcasted_at: 1.hour.ago)
      ]
    end

    before do
      allow(TrackScraper::MytunerApiProcessor).to receive(:new).and_return(processor)
      allow(processor).to receive(:all_played_songs).and_return(played_songs)
    end

    it 'calls SongImporter for each played song', :aggregate_failures do
      importer = instance_double(SongImporter, import: true)
      allow(SongImporter).to receive(:new).and_return(importer)

      described_class.new.perform(radio_station.id)

      expect(SongImporter).to have_received(:new).with(radio_station: radio_station, played_song: played_songs[0])
      expect(SongImporter).to have_received(:new).with(radio_station: radio_station, played_song: played_songs[1])
    end

    it 'skips songs that already have an air play at the same broadcasted_at', :aggregate_failures do
      create(:air_play, radio_station: radio_station, broadcasted_at: played_songs.first.broadcasted_at)
      importer = instance_double(SongImporter, import: true)
      allow(SongImporter).to receive(:new).and_return(importer)

      described_class.new.perform(radio_station.id)

      expect(SongImporter).to have_received(:new).once
      expect(SongImporter).to have_received(:new).with(radio_station: radio_station, played_song: played_songs[1])
    end

    context 'when processor returns no songs' do
      before { allow(processor).to receive(:all_played_songs).and_return([]) }

      it 'does not call SongImporter' do
        allow(SongImporter).to receive(:new)

        described_class.new.perform(radio_station.id)

        expect(SongImporter).not_to have_received(:new)
      end
    end
  end
end
