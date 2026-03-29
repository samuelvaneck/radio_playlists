# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sitemap', type: :request do
  describe 'GET /sitemap.xml' do
    let!(:radio_station) { create(:radio_station, name: 'Sitemap Test Radio', slug: 'sitemap-test-radio') }
    let!(:song) { create(:song, title: 'Test Song') }
    let!(:artist) { create(:artist, name: 'Test Artist') }

    before { get '/sitemap.xml' }

    it 'returns XML content type', :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/xml')
    end

    it 'includes static pages' do
      expect(response.body).to include('<loc>https://airplays.nl/</loc>')
    end

    it 'includes radio station pages' do
      expect(response.body).to include('<loc>https://airplays.nl/radio_stations/sitemap-test-radio</loc>')
    end

    it 'includes song pages' do
      expect(response.body).to include("<loc>https://airplays.nl/songs/#{song.id}</loc>")
    end

    it 'includes artist pages' do
      expect(response.body).to include("<loc>https://airplays.nl/artists/#{artist.id}</loc>")
    end

    it 'includes lastmod for dynamic pages' do
      expect(response.body).to include("<lastmod>#{radio_station.updated_at.strftime('%Y-%m-%d')}</lastmod>")
    end
  end
end
