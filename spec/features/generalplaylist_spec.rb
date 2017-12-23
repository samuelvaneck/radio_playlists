require 'rails_helper'

feature do
  before do
    @radio_2 = FactoryBot.create(:radiostation, name: "Radio 2")
    @radio_3fm = FactoryBot.create(:radiostation, name: "Radio 3FM")
    @radio_veronica = FactoryBot.create(:radiostation, name: "Radio Veronica")
    @radio_538 = FactoryBot.create(:radiostation, name: "Radio 538")
    @sublime_fm = FactoryBot.create(:radiostation, name: "Sublime FM")
    @groot_nieuws_radio = FactoryBot.create(:radiostation, name: "Groot Nieuws Radio")
    @sky_radio = FactoryBot.create(:radiostation, name: "Sky Radio")
    @qmusic = FactoryBot.create(:radiostation, name: "Qmusic")


    @playlists_radio_2 = FactoryBot.create_list(:generalplaylist, 5, radiostation: @radio_2, created_at: 1.day.ago)
    @playlists_radio_3fm = FactoryBot.create_list(:generalplaylist, 5, radiostation: @radio_3fm, created_at: 1.week.ago)
    @playlists_radio_veronica = FactoryBot.create_list(:generalplaylist, 5, radiostation: @radio_veronica, created_at: 1.month.ago)
    @playlists_radio_538 = FactoryBot.create_list(:generalplaylist, 5, radiostation: @radio_538, created_at: 1.year.ago)
    @playlists_sublime_fm = FactoryBot.create_list(:generalplaylist, 5, radiostation: @sublime_fm, created_at: 1.hour.ago)
    @playlists_groot_nieuws_radio = FactoryBot.create_list(:generalplaylist, 5, radiostation: @groot_nieuws_radio, created_at: 2.hours.ago)
    @playlists_sky_radio = FactoryBot.create_list(:generalplaylist, 5, radiostation: @sky_radio, created_at: 3.hours.ago)
    @playlists_qmusic = FactoryBot.create_list(:generalplaylist, 5, radiostation: @qmusic, created_at: 1.minute.ago)
  end

  describe "Visiting the index page", js: true do
    it "is expected to have the page title" do
      visit generalplaylists_path

      expect(page).to have_content "Radio Playlists"
    end

    it "is expected that the generplaylist table has 10 rows" do
      visit generalplaylists_path
      find(:xpath, '//*[@id="0"]').click

      expect(page).to have_selector("#playlists-table tr", count: 10)
    end

    it "is expected that the generalplaylists table has the latest 5 songs" do
      visit generalplaylists_path
      find(:xpath, '//*[@id="0"]').click

      expect(page).to have_content @playlists_qmusic[0].song.title
      expect(page).to have_content @playlists_qmusic[4].song.title
    end

    it "is expected that the top songs table has 10 rows" do
      visit generalplaylists_path
      find(:xpath, '//*[@id="section-1"]/div[2]/div/div[2]/h3/i').click

      expect(page).to have_selector("#top-songs-table tr", count: 10)
    end

    it "is expected that the top artists table has 10 rows" do
      visit generalplaylists_path
      find(:xpath, '//*[@id="section-1"]/div[2]/div/div[3]/h3/i').click

      expect(page).to have_selector("#top-artists-table tr", count: 10)
    end
  end
end
