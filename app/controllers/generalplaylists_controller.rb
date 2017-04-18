class GeneralplaylistsController < ApplicationController

  def index
    if params[:search_top_song].present?
      @top_songs = Song.joins(:artist).where("songs.title ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%")
    else
      @top_songs = Song.order(total_counter: :DESC).limit(5)
    end
    # if params[:set_counter_top_songs].present?
    #   case params[:set_counter_top_songs]
    #   when "day_counter" then
    #     @top_songs = @top_songs.where("created_at > ?", Date.today)
    #   when "week_counter" then
    #     puts "week_counter"
    #   when "month_counter" then
    #     puts "month_counter"
    #   when "year_counter" then
    #     puts "year_counter"
    #   when "total_counter" then
    #     puts "total_counter"
    #   end
    # end
    @top_songs.order!(total_counter: :DESC)
    @top_songs = @top_songs.reorder!("#{params[:set_counter_top_songs]} DESC") if params[:set_counter_top_songs]

    if params[:search_top_artist].present?
      @top_artists = Artist.where("name ILIKE ?", "%#{params[:search_top_artist]}%")
    else
      @top_artists = Artist.order(total_counter: :DESC).limit(5)
    end
    @top_artists.order!(total_counter: :DESC)
    @top_artists.reorder!("#{params[:set_counter_top_artists]} DESC") if params[:set_counter_top_artists]

    @target = params[:target]
  end

  # def song_details
  #   @details = Song.where("fullname ILIKE ?", "%#{params[:search_fullname]}%")
  # end
  #
  # def today_played_songs
  #   @today_played_songs = Generalplaylist.today_played_songs.paginate(page: params[:page]).per_page(10)
  # end
  #
  # def top_songs
  #   if params[:page].present?
  #     @counter = (params[:page].to_i * 10) -10
  #   else
  #     @counter = 0
  #   end
  #   @top_songs = Generalplaylist.top_songs.paginate(page: params[:page]).per_page(10)
  # end
  #
  # def top_artists
  #   if params[:page].present?
  #     @counter = (params[:page].to_i * 10) -10
  #   else
  #     @counter = 0
  #   end
  #   @top_artists = Generalplaylist.top_artists.paginate(page: params[:page]).per_page(10)
  # end
  #
  # def autocomplete
  #   @results = Song.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
  #   render json: @results.map(&:fullname)
  # end

end
