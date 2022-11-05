# frozen_string_literal: true

require 'rails_helper'

describe SongsController do
  let(:artist) { FactoryBot.create :artist }
  let(:song) { FactoryBot.create :song, artists: [artist] }
  let(:playlist_1) { FactoryBot.create :generalplaylist, :filled, song: }
  let(:playlist_2) { FactoryBot.create :generalplaylist, :filled, song: }
  let(:playlists) { FactoryBot.create_list :generalplaylist, 5, :filled }

  describe 'GET #index' do
    context 'with no search params' do
      let(:json) do
        JSON(response.body).sort_by { |_song, counter| counter }
                           .reverse
                           .first
      end
      let(:expected) do
        [SongSerializer.new(Song.find(song.id)).serializable_hash.as_json, 2]
      end

      before do
        playlist_1
        playlist_2
        playlists
        get :index, params: { format: :json }
      end

      it 'returns status OK/200' do
        expect(response.status).to eq 200
      end

      it 'returns all the playlists songs' do
        expect(json).to eq expected
      end
    end

    context 'with search params' do
      let(:json) { JSON.parse(response.body) }
      let(:serialized_song) { SongSerializer.new(Song.find(song.id)).serializable_hash.as_json }

      before do
        playlist_1
        playlist_2
        playlists
      end

      it 'only returns the search song' do
        get :index, params: { format: :json, search_term: song.title }
        json = JSON.parse(response.body)

        expect(json).to eq [[serialized_song, 2]]
      end
    end

    context 'filtering by radio station' do
      let(:json) { JSON.parse(response.body) }
      let(:serialized_song) { SongSerializer.new(Song.find(song.id)).serializable_hash.as_json }

      before do
        playlist_1
        playlist_2
        playlists
      end

      it 'only returns the songs that are played by the radio_station' do
        get :index, params: { format: :json, radio_station_id: playlist_1.radio_station.id }

        expect(json).to eq [[serialized_song, 1]]
      end
    end
  end
end
