# frozen_string_literal: true

require 'rails_helper'

describe SongsController do
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

      it 'returns all the playlists songs' do
        json = JSON.parse(response.body).sort_by { |song_id, _counter| song_id }
        expected = [[song.id, 2],
                    [playlists[0].song.id, 1],
                    [playlists[1].song.id, 1],
                    [playlists[2].song.id, 1],
                    [playlists[3].song.id, 1],
                    [playlists[4].song.id, 1]]

        expect(json).to eq expected
      end
    end

    context 'with search params' do
      before do
        playlist_1
        playlist_2
        playlists
      end
      it 'only returns the search song' do
        get :index, params: { format: :json, search_term: song.fullname }
        json = JSON.parse(response.body)

        expect(json).to eq [[song.id, 2]]
      end
    end

    context 'filtering by radiostation' do
      before do
        playlist_1
        playlist_2
        playlists
      end
      it 'only returns the songs that are played by the radiostation' do
        get :index, params: { format: :json, radiostation_id: playlist_1.radiostation.id }
        json = JSON.parse(response.body)

        expect(json).to eq [[song.id, 1]]
      end
    end
  end
end