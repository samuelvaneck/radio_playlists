class GeneralplaylistsController < ApplicationController

  def index
    @generalplaylists = Generalplaylist.order(created_at: :desc).limit(5)
    @veronicaplaylists = Generalplaylist.where(radiostation_id: '1').order(created_at: :desc).limit(5)
    @radio538playlists = Generalplaylist.where(radiostation_id: '2').order(created_at: :desc).limit(5)
    @radio2playlists = Generalplaylist.where(radiostation_id: '3').order(created_at: :desc).limit(5)
    @sublimefmplaylists = Generalplaylist.where(radiostation_id: '4').order(created_at: :desc).limit(5)
    @gnrplaylists = Generalplaylist.where(radiostation_id: '5').order(created_at: :desc).limit(5)
    @top5songsweek = Song.order(week_counter: :desc).limit(5)
    @counter = 0
  end

end
