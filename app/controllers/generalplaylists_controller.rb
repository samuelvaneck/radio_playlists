class GeneralplaylistsController < ApplicationController

  def index
    @generalplaylists = Generalplaylist.order(created_at: :DESC).limit(10)
    @top_10_songs_week = Song.order(week_counter: :DESC).limit(10)
    @top_10_artists_week = Artist.order(week_counter: :DESC).limit(10)
    @counter_songs = 0
    @counter_artists = 0

    @veronicaplaylists = Generalplaylist.where(radiostation_id: '1').order(created_at: :DESC).limit(10)
    @top_songs_radio_veronica = Generalplaylist.top_songs_radiostation(1)
    @top_artists_radio_veronica = Generalplaylist.top_artists_radiostation(1)
    @counter_top_songs_radio_veronica = 0
    @counter_top_artists_radio_veronica = 0

    @radio538playlists = Generalplaylist.where(radiostation_id: '2').order(created_at: :DESC).limit(10)
    @top_songs_radio_538 = Generalplaylist.top_songs_radiostation(2)
    @top_artists_radio_538 = Generalplaylist.top_artists_radiostation(2)
    @counter_top_songs_radio_538 = 0
    @counter_top_artists_radio_538 = 0

    @sublimefmplaylists = Generalplaylist.where(radiostation_id: '3').order(created_at: :DESC).limit(10)
    @top_songs_sublime_fm = Generalplaylist.top_songs_radiostation(3)
    @top_artists_sublime_fm = Generalplaylist.top_artists_radiostation(3)
    @counter_top_songs_sublime_fm = 0
    @counter_top_artists_sublime_fm = 0

    @radio2playlists = Generalplaylist.where(radiostation_id: '4').order(created_at: :DESC).limit(10)
    @top_songs_radio_2 = Generalplaylist.top_songs_radiostation(4)
    @top_artists_radio_2 = Generalplaylist.top_artists_radiostation(4)
    @counter_top_songs_radio_2 = 0
    @counter_top_artists_radio_2 = 0

    @gnrplaylists = Generalplaylist.where(radiostation_id: '5').order(created_at: :DESC).limit(10)
    @top_songs_grootnieuws_radio = Generalplaylist.top_songs_radiostation(5)
    @top_artists_grootnieuws_radio = Generalplaylist.top_artists_radiostation(5)
    @counter_top_songs_grootnieuws_radio = 0
    @counter_top_artists_grootnieuws_radio = 0

    @sky_radio_playlists = Generalplaylist.where(radiostation_id: '6').order(created_at: :DESC).limit(10)
    @top_songs_sky_radio = Generalplaylist.top_songs_radiostation(6)
    @top_artists_sky_radio = Generalplaylist.top_artists_radiostation(6)
    @counter_top_songs_sky_radio = 0
    @counter_top_artists_sky_radio = 0

    @radio_3fm_playlists = Generalplaylist.where(radiostation_id: '7').order(created_at: :DESC).limit(10)
    @top_songs_radio_3fm = Generalplaylist.top_songs_radiostation(7)
    @top_artists_radio_3fm = Generalplaylist.top_artists_radiostation(7)
    @counter_top_songs_radio_3fm = 0
    @counter_top_artists_radio_3fm = 0

    @q_music_playlists = Generalplaylist.where(radiostation_id: '8').order(created_at: :DESC).limit(10)
    @top_songs_q_music = Generalplaylist.top_songs_radiostation(8)
    @top_artists_q_music = Generalplaylist.top_artists_radiostation(8)
    @counter_top_songs_q_music = 0
    @counter_top_artists_q_music = 0

  end

  def song_details
    @details = Song.where("fullname ILIKE ?", "%#{params[:search_fullname]}%")
  end

  def today_played_songs
    @today_played_songs = Generalplaylist.today_played_songs.paginate(page: params[:page]).per_page(10)
  end

  def top_songs
    if params[:page].present?
      @counter = (params[:page].to_i * 10) -10
    else
      @counter = 0
    end
    @top_songs = Generalplaylist.top_songs.paginate(page: params[:page]).per_page(10)
  end

  def top_artists
    if params[:page].present?
      @counter = (params[:page].to_i * 10) -10
    else
      @counter = 0
    end
    @top_artists = Generalplaylist.top_artists.paginate(page: params[:page]).per_page(10)
  end

  def autocomplete
    @results = Song.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
    render json: @results.map(&:fullname)
  end

end
