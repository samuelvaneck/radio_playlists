class GeneralplaylistsController < ApplicationController

  def index
  # Playlist search options
    if params[:search_playlists].present? && params[:radiostation_id].present? && params[:set_counter_playlists].present?
      case params[:set_counter_playlists]
        when "day"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("radiostation_id = ?", "#{params[:radiostation_id]}").where("generalplaylists.created_at > ?", Date.today.beginning_of_day).limit(25)
        when "week"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("radiostation_id = ?", "#{params[:radiostation_id]}").where("generalplaylists.created_at > ?", Date.today.beginning_of_week).limit(25)
        when "month"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("radiostation_id = ?", "#{params[:radiostation_id]}").where("generalplaylists.created_at > ?", Date.today.beginning_of_month).limit(25)
        when "year"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("radiostation_id = ?", "#{params[:radiostation_id]}").where("generalplaylists.created_at > ?", Date.today.beginning_of_year).limit(25)
        when "total"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("radiostation_id = ?", "#{params[:radiostation_id]}").limit(25)
      end

    elsif params[:search_playlists].present? && params[:radiostation_id].present?
      @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.title ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("radiostation_id = ?", "#{params[:radiostation_id]}").limit(25)

    elsif params[:search_playlists].present? && params[:set_counter_playlists].present?
      case params[:set_counter_playlists]
        when "day"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_day).limit(25)
        when "week"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_week).limit(25)
        when "month"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_month).limit(25)
        when "year"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_year).limit(25)
        when "total"
          @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%")
      end

    elsif params[:radiostation_id].present? && params[:set_counter_playlists].present?
      case params[:set_counter_playlists]
        when "day"
          @playlists = Generalplaylist.where("radiostation_id = ?", "#{params[:radiostation_id]}").where("created_at > ?", Date.today.beginning_of_day).limit(25)
        when "week"
          @playlists = Generalplaylist.where("radiostation_id = ?", "#{params[:radiostation_id]}").where("created_at > ?", Date.today.beginning_of_week).limit(25)
        when "month"
          @playlists = Generalplaylist.where("radiostation_id = ?", "#{params[:radiostation_id]}").where("created_at > ?", Date.today.beginning_of_month).limit(25)
        when "year"
          @playlists = Generalplaylist.where("radiostation_id = ?", "#{params[:radiostation_id]}").where("created_at > ?", Date.today.beginning_of_year).limit(25)
        when "total"
          @playlists = Generalplaylist.where("radiostation_id = ?", "#{params[:radiostation_id]}")
      end

    elsif params[:search_playlists].present?
      @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").limit(25)

    elsif params[:radiostation_id].present?
      @playlists = Generalplaylist.where("radiostation_id = ?", "#{params[:radiostation_id]}").limit(25)

    elsif params[:set_counter_playlists].present?
      case params[:set_counter_playlists]
        when "day"
          @playlists = Generalplaylist.where("created_at > ?", Date.today.beginning_of_day).limit(25)
        when "week"
          @playlists = Generalplaylist.where("created_at > ?", Date.today.beginning_of_week).limit(25)
        when "month"
          @playlists = Generalplaylist.where("created_at > ?", Date.today.beginning_of_month).limit(25)
        when "year"
          @playlists = Generalplaylist.where("created_at > ?", Date.today.beginning_of_year).limit(25)
        when "total"
          @playlists = Generalplaylist.all.limit(25)
      end

    else
      @playlists = Generalplaylist.order(created_at: :DESC).limit(25)
    end

    @playlists.order!(created_at: :DESC)

  # Song search options
    @songs_counter = Generalplaylist.group(:song_id).count
    if params[:search_top_song].present? && params[:radiostation_id].present? && params[:set_counter_top_songs].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      case params[:set_counter_top_songs]
        when "day"
          @top_songs = Song.joins(:artist, :radiostations, :generalplaylists).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_day).order(day_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_day).group(:song_id).count
        when "week"
          @top_songs = Song.joins(:artist, :radiostations, :generalplaylists).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("radiostations.name = ?", radiostation.name)..where("generalplaylists.created_at > ?", Date.today.beginning_of_week).order(week_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_week).group(:song_id).count
        when "month"
          @top_songs = Song.joins(:artist, :radiostations, :generalplaylists).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_month).order(month_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_month).group(:song_id).count
        when "year"
          @top_songs = Song.joins(:artist, :radiostations, :generalplaylists).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("radiostations.name = ?", radiostation.name)..where("generalplaylists.created_at > ?", Date.today.beginning_of_year).order(year_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_year).group(:song_id).count
        when "total"
          @top_songs = Song.joins(:artist, :radiostations).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("radiostations.name = ?", radiostation.name).order(total_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("radiostation_id = ?", params[:radiostation_id]).group(:song_id).count
          @top_songs.reorder!(total_counter: :DESC)
      end

    elsif params[:search_top_song].present? && params[:radiostation_id].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      @top_songs = Song.joins(:artist, :radiostations).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("radiostations.name = ?", radiostation.name).limit(25)

    elsif params[:search_top_song].present? && params[:set_counter_top_songs].present?
      case params[:set_counter_top_songs]
        when "day"
          @top_songs = Song.joins(:artist, :generalplaylists).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_day).order(day_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("created_at > ?", Date.today.beginning_of_day).group(:song_id).count
        when "week"
          @top_songs = Song.joins(:artist, :generalplaylists).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_week).order(week_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("created_at > ?", Date.today.beginning_of_week).group(:song_id).count
        when "month"
          @top_songs = Song.joins(:artist, :generalplaylists).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_month).order(month_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("created_at > ?", Date.today.beginning_of_month).group(:song_id).count
        when "year"
          @top_songs = Song.joins(:artist, :generalplaylists).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_year).order(year_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("created_at > ?", Date.today.beginning_of_year).group(:song_id).count
        when "total"
          @top_songs = Song.joins(:artist).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").order(total_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.group(:song_id).count
      end

    elsif params[:radiostation_id].present? && params[:set_counter_top_songs].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      case params[:set_counter_top_songs]
      when "day"
        @top_songs = Song.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_day).order(day_counter: :DESC).limit(25).uniq
        @songs_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_day).group(:song_id).count
      when "week"
        @top_songs = Song.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_week).order(week_counter: :DESC).limit(25).uniq
        @songs_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_week).group(:song_id).count
      when "month"
        @top_songs = Song.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_month).order(month_counter: :DESC).limit(25).uniq
        @songs_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_month).group(:song_id).count
      when "year"
        @top_songs = Song.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_year).order(year_counter: :DESC).limit(25).uniq
        @songs_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_year).group(:song_id).count
      when "total"
        @top_songs = Song.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).order(total_counter: :DESC).limit(25).uniq
        @songs_counter = Generalplaylist.where("radiostation_id = ?", params[:radiostation_id]).group(:song_id).count
      end

    elsif params[:search_top_song].present?
      @top_songs = Song.joins(:artist).where("songs.fullname ILIKE ? OR artists.name ILIKE ?", "%#{params[:search_top_song]}%", "%#{params[:search_top_song]}%").order(total_counter: :DESC).limit(25).uniq

    elsif params[:radiostation_id].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      @top_songs = Song.joins(:radiostations).where("radiostations.name = ?", radiostation.name).order(total_counter: :DESC).limit(25).uniq

    elsif params[:set_counter_top_songs].present?
      case params[:set_counter_top_songs]
        when "day"
          @top_songs = Song.joins(:generalplaylists).where("generalplaylists.created_at > ?", Date.today.beginning_of_day).order(day_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("created_at > ?", Date.today.beginning_of_day).group(:song_id).count
        when "week"
          @top_songs = Song.joins(:generalplaylists).where("generalplaylists.created_at > ?", Date.today.beginning_of_week).order(week_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("created_at > ?", Date.today.beginning_of_week).group(:song_id).count
        when "month"
          @top_songs = Song.joins(:generalplaylists).where("generalplaylists.created_at > ?", Date.today.beginning_of_month).order(month_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("created_at > ?", Date.today.beginning_of_month).group(:song_id).count
        when "year"
          @top_songs = Song.joins(:generalplaylists).where("generalplaylists.created_at > ?", Date.today.beginning_of_year).order(year_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.where("created_at > ?", Date.today.beginning_of_year).group(:song_id).count
        when "total"
          @top_songs = Song.all.order(total_counter: :DESC).order(total_counter: :DESC).limit(25).uniq
          @songs_counter = Generalplaylist.group(:song_id).count
      end

    else
      @top_songs = Song.order(total_counter: :DESC).limit(25).uniq
    end


  # Artist search options
    @artists_counter = Generalplaylist.group(:artist_id).count

    if params[:search_top_artist].present? && params[:radiostation_id].present? && params[:set_counter_top_artists].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      case params[:set_counter_top_artists]
        when "day"
          @top_artists = Artist.joins(:radiostations, :generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_day).order(day_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_day).group(:artist_id).count
        when "week"
          @top_artists = Artist.joins(:radiostations, :generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_week).order(week_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_week).group(:artist_id).count
        when "month"
          @top_artists = Artist.joins(:radiostations, :generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_month).order(month_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_month).group(:artist_id).count
        when "year"
          @top_artists = Artist.joins(:radiostations, :generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_year).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_year).group(:artist_id).count
        when "total"
          @top_artists = Artist.joins(:radiostations).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("radiostations.name = ?", radiostation.name).order(total_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ?", params[:radiostation_id]).group(:artist_id).count
        end

    elsif params[:search_top_artist].present? && params[:radiostation_id].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      @top_artists = Artist.joins(:radiostations, :generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("radiostations.name = ?", radiostation.name).order(total_counter: :DESC).limit(25)

    elsif params[:search_top_artist].present? && params[:set_counter_top_artists].present?
      case params[:set_counter_top_artists]
        when "day"
          @top_artists = Artist.joins(:generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_day).order(day_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_day).group(:artist_id).count
        when "week"
          @top_artists = Artist.joins(:generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_week).order(week_counter: :DESC.limit(25)).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_week).group(:artist_id).count
        when "month"
          @top_artists = Artist.joins(:generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_month).order(month_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_month).group(:artist_id).count
        when "year"
          @top_artists = Artist.joins(:generalplaylists).where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").where("generalplaylists.created_at > ?", Date.today.beginning_of_year).order(year_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_year).group(:artist_id).count
        when "total"
          @top_artists = Artist.where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").order(total_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ?", params[:radiostation_id]).group(:artist_id).count
        end

    elsif params[:radiostation_id].present? && params[:set_counter_top_artists].present?
      radiostation = Radiostation.find(params[:radiostation_id])
      case params[:set_counter_top_artists]
        when "day"
          @top_artists = Artist.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_day).order(day_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_day).group(:artist_id).count
        when "week"
          @top_artists = Artist.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_week).order(week_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_week).group(:artist_id).count
        when "month"
          @top_artists = Artist.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_month).order(month_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_month).group(:artist_id).count
        when "year"
          @top_artists = Artist.joins(:radiostations, :generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_year).order(year_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_year).group(:artist_id).count
        when "total"
          @top_artists = Artist.joins(:radiostations).where("radiostations.name = ?", radiostation.name).order(total_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ?", params[:radiostation_id]).group(:artist_id).count
        end

    elsif params[:search_top_artist].present?
      @top_artists = Artist.where("artists.name ILIKE ?", "%#{params[:search_top_artist]}%").order(total_counter: :DESC).limit(25).uniq

    elsif params[:radiostation_id].present?
      @top_artists = Artist.joins(:radiostations).where("radiostations.name = ?", radiostation.name).order(total_counter: :DESC).limit(25).uniq

    elsif params[:set_counter_top_artists].present?
      case params[:set_counter_top_artists]
        when "day"
          @top_artists = Artist.joins(:generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_day).order(day_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_day).group(:artist_id).count
        when "week"
          @top_artists = Artist.joins(:generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_week).order(week_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_week).group(:artist_id).count
        when "month"
          @top_artists = Artist.joins(:generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_month).order(month_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_month).group(:artist_id).count
        when "year"
          @top_artists = Artist.joins(:generalplaylists).where("radiostations.name = ?", radiostation.name).where("generalplaylists.created_at > ?", Date.today.beginning_of_year).order(year_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ? AND created_at > ?", params[:radiostation_id], Date.today.beginning_of_year).group(:artist_id).count
        when "total"
          @top_artists = Artist.order(total_counter: :DESC).order(total_counter: :DESC).limit(25).uniq
          @artists_counter = Generalplaylist.where("radiostation_id = ?", params[:radiostation_id]).group(:artist_id).count
        end
    else
      @top_artists = Artist.order(total_counter: :DESC).limit(25)
    end

    @target = params[:target]
  end

  # def autocomplete
  #   @results = Song.order(:fullname).where("fullname ILIKE ?", "%#{params[:term]}%").limit(10)
  #   render json: @results.map(&:fullname)
  # end

end
