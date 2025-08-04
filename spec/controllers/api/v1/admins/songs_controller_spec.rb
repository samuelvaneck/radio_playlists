# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Admins::SongsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:song) { create(:song, id_on_youtube: 'old_id') }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    subject(:get_index) { get :index, params: { format: :json } }

    let(:ordered_song_ids) { Song.order(created_at: :desc).pluck(:id).map(&:to_s) }

    context 'when there are songs' do
      before { create_list(:song, 3) }

      it 'returns status OK/200' do
        get_index
        expect(response.status).to eq 200
      end

      it 'returns all songs' do
        get_index
        expect(json[:data].count).to eq(3)
      end

      it 'returns the songs in descending order of creation' do
        get_index
        expect(json[:data].map { |s| s[:id] }).to eq(ordered_song_ids)
      end
    end

    context 'when searching for a song' do
      subject(:get_with_search_param) { get :index, params: { format: :json, search_term: song.title } }

      it 'returns the matching song' do
        get_with_search_param
        expect(json[:data].map { |s| s[:id] }).to include(song.id.to_s)
      end
    end
  end

  describe 'PATCH #update' do
    subject(:patch_update) { patch :update, params: }

    context 'with valid params' do
      let(:params) { { id: song.id, song: { id_on_youtube: 'new_id' }, format: :json } }

      it 'updates the song' do
        patch_update
        expect(song.reload.id_on_youtube).to eq('new_id')
      end

      it 'returns status OK/200' do
        patch_update
        expect(response.status).to eq 200
      end
    end

    context 'with invalid params' do
      let(:params) { { id: song.id, song: { no_existing_attribute: nil }, format: :json } }

      it 'does not update the song' do
        expect { patch_update }.not_to(change(song, :reload))
      end

      it 'returns status 200' do
        patch_update
        expect(response.status).to eq 200
      end
    end
  end
end
