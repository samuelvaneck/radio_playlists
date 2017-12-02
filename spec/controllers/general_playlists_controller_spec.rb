require 'rails_helper'

describe GeneralplaylistsController do

  describe "GET #index" do
    it 'renders the index page' do
      get :index

      expect(response).to render_template :index
      expect(response.status).to eq 200
    end
  end
end
