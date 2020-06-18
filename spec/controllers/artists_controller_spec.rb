# frozen_string_literal: true

require 'rails_helper'

describe ArtistsController do
  let(:artist) { FactoryBot.create :artist }
  let(:song) { FactoryBot.create :song, artists: [artist] }
  let(:playlist_1) { FactoryBot.create :generalplaylist, :filled, song: song }
  let(:playlist_2) { FactoryBot.create :generalplaylist, :filled, song: song }
  let(:playlists) { FactoryBot.create_list :generalplaylist, 5, :filled }
  
  describe 'GET #index' do
    context 'with no search params' do
      before do
        playlist_1
        playlist_2
        playlists
        get :index, params: { format: :json } 
      end
      it 'returns status OK/200' do
        expect(response.status).to eq 200
      end

      it 'returns all the playlists artists' do
        json = JSON.parse(response.body).sort_by { |artist_id, _counter| artist_id }
        expected = [[artist.id, 2], [playlists[0].song.artists.first.id, 1], [playlists[1].song.artists.first.id, 1], [playlists[2].song.artists.first.id, 1], [playlists[3].song.artists.first.id, 1], [playlists[4].song.artists.first.id, 1]]

         expect(json).to eq(expected)
      end
    end

    context 'with search params' do
      before do
        playlist_1
        playlist_2
        playlists
      end
      it 'only returns the search artist' do
        get :index, params: { format: :json, search_term: artist.name }
        json = JSON.parse(response.body)

        expect(json).to eq [[artist.id, 2]]
      end
    end

    context 'filtering by radiostation' do
      before do
        playlist_1
        playlist_2
        playlists
      end
      it 'only returns the artists that are played by the radiostation' do
        get :index, params: { format: :json, radiostation_id: playlist_1.radiostation.id }
        json = JSON.parse(response.body)

        debugger

        expect(json).to eq [[artist.id, 1]]
      end
    end
  end
end