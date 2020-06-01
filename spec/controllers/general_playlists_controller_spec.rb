# frozen_string_literal: true

require 'rails_helper'

describe GeneralplaylistsController do
  let(:playlist) { FactoryBot.create :generalplaylist, :filled }
  let(:playlists) { FactoryBot.create_list :generalplaylist, 5, :filled }

  describe "GET #index" do
    before do
      playlist
      playlists
    end
    context 'with no search params' do
      it 'renders the index page' do
        get :index
  
        expect(response).to render_template :index
        expect(response.status).to eq 200
      end
      
      it 'sets the playlists' do
        get :index, format: :json

        expect(JSON.parse(response.body)['data'].count).to eq 6
      end
    end

    context 'with search param' do
      it 'only fetches the playlists that matches the song title or artitst name' do
        get :index, params: { format: :json, search_term: playlist.artist.name }

        expect(JSON.parse(response.body)['data'][0]['id']).to eq playlist.id.to_s
      end
    end

    context 'filtered by radiostation' do
      it 'only fetches the playlists that are played on the radiostation' do
        get :index, params: { format: :json, radiostation_id: playlist.radiostation.id }

        expect(JSON.parse(response.body)['data'][0]['id']).to eq playlist.id.to_s
      end
    end
  end
end
