require 'rails_helper'

feature do
  before do
    @generalplaylists = FactoryBot.create_list(:generalplaylist, 5)
  end

  describe "Visiting the index page" do
    it "is expected to have the page title" do
      visit generalplaylists_path

      expect(page).to have_content "Radio Playlists"
    end
  end
end
