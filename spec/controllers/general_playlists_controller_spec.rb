require 'rails_helper'

describe GeneralplaylistsController do

  describe "GET #index" do
    before do
      @generalplaylists = FactoryBot.create_list(:generalplaylist, 5)
    end

    def sorted_generalplaylist
      @sorted_playlist = @generalplaylists.sort_by(&:created_at).reverse
    end

    it 'renders the index page' do
      get :index

      expect(assigns(:playlists)).to eq sorted_generalplaylist
      expect(response).to render_template :index
      expect(response.status).to eq 200
    end
  end
end
