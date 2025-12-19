# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Admins::ArtistsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:artist) { create(:artist, website_url: 'https://old-website.com', instagram_url: 'https://instagram.com/old') }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    subject(:get_index) { get :index, params: { format: :json } }

    let(:ordered_artist_ids) { Artist.order(created_at: :desc).pluck(:id).map(&:to_s) }

    context 'when there are artists' do
      before { create_list(:artist, 3) }

      it 'returns status OK/200' do
        get_index
        expect(response.status).to eq 200
      end

      it 'returns all artists' do
        get_index
        expect(json[:data].count).to eq(3)
      end

      it 'returns the artists in descending order of creation' do
        get_index
        expect(json[:data].map { |a| a[:id] }).to eq(ordered_artist_ids)
      end
    end

    context 'when searching for an artist' do
      subject(:get_with_search_param) { get :index, params: { format: :json, search_term: artist.name } }

      it 'returns the matching artist' do
        get_with_search_param
        expect(json[:data].map { |a| a[:id] }).to include(artist.id.to_s)
      end
    end
  end

  describe 'PATCH #update' do
    subject(:patch_update) { patch :update, params: }

    context 'with valid params' do
      let(:params) { { id: artist.id, artist: { website_url: 'https://new-website.com', instagram_url: 'https://instagram.com/new' }, format: :json } }

      it 'updates the artist website_url' do
        patch_update
        expect(artist.reload.website_url).to eq('https://new-website.com')
      end

      it 'updates the artist instagram_url' do
        patch_update
        expect(artist.reload.instagram_url).to eq('https://instagram.com/new')
      end

      it 'returns status OK/200' do
        patch_update
        expect(response.status).to eq 200
      end
    end

    context 'with only website_url' do
      let(:params) { { id: artist.id, artist: { website_url: 'https://another-website.com' }, format: :json } }

      it 'updates only the website_url' do
        patch_update
        expect(artist.reload.website_url).to eq('https://another-website.com')
        expect(artist.reload.instagram_url).to eq('https://instagram.com/old')
      end
    end

    context 'with only instagram_url' do
      let(:params) { { id: artist.id, artist: { instagram_url: 'https://instagram.com/another' }, format: :json } }

      it 'updates only the instagram_url' do
        patch_update
        expect(artist.reload.instagram_url).to eq('https://instagram.com/another')
        expect(artist.reload.website_url).to eq('https://old-website.com')
      end
    end

    context 'with invalid params' do
      let(:params) { { id: artist.id, artist: { non_existing_attribute: nil }, format: :json } }

      it 'does not update the artist' do
        expect { patch_update }.not_to(change(artist, :reload))
      end

      it 'returns status 200' do
        patch_update
        expect(response.status).to eq 200
      end
    end
  end
end
