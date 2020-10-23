# frozen_string_literal: true

require 'rails_helper'

describe GeneralplaylistsController do
  let(:radiostation_one) { FactoryBot.create :radiostation }
  let(:radiostation_two) { FactoryBot.create :radiostation }
  let(:artist_one) { FactoryBot.create :artist }
  let(:song_one) { FactoryBot.create :song, :artists => [artist_one] }
  let(:artist_two) { FactoryBot.create :artist }
  let(:song_two) { FactoryBot.create :song, :artists => [artist_two] }
  let(:playlist) { FactoryBot.create :generalplaylist, :radiostation => radiostation_one, :song => song_one }
  let(:playlists) { FactoryBot.create_list :generalplaylist, 5, :radiostation => radiostation_two, :song => song_two }

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
        get :index, :format => :json

        expect(JSON.parse(response.body)['data'].count).to eq 6
      end
    end

    context 'with search param' do
      it 'only fetches the playlists that matches the song title or artitst name' do
        get :index, :params => { :format => :json, :search_term => song_one.title }

        expect(JSON.parse(response.body)['data'][0]['id']).to eq playlist.id.to_s
      end
    end

    context 'filtered by radiostation' do
      it 'only fetches the playlists that are played on the radiostation' do
        get :index, :params => { :format => :json, :radiostation_id => radiostation_one.id }

        expect(JSON.parse(response.body)['data'][0]['id']).to eq playlist.id.to_s
      end
    end
  end
end
