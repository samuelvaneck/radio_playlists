# frozen_string_literal: true

class GeneralplaylistsController < ApplicationController

  def index

  # Playlist search options
    if params[:search_playlists].present? && params[:playlists_radiostation_id].present? && params[:set_counter_playlists].present?
      @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("radiostation_id = ?", "#{params[:playlists_radiostation_id]}").limit(params[:set_limit_playlists])
      set_time_playlists

    elsif params[:search_playlists].present? && params[:playlists_radiostation_id].present?
      @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").where("radiostation_id = ?", "#{params[:playlists_radiostation_id]}").limit(params[:set_limit_playlists])

    elsif params[:search_playlists].present? && params[:set_counter_playlists].present?
      @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").limit(params[:set_limit_playlists])
      set_time_playlists

    elsif params[:playlists_radiostation_id].present? && params[:set_counter_playlists].present?
      @playlists = Generalplaylist.where("radiostation_id = ?", "#{params[:playlists_radiostation_id]}").limit(params[:set_limit_playlists])
      set_time_playlists

    elsif params[:search_playlists].present?
      @playlists = Generalplaylist.joins(:artist, :song).where("artists.name ILIKE ? OR songs.fullname ILIKE ?", "%#{params[:search_playlists]}%", "%#{params[:search_playlists]}%").limit(params[:set_limit_playlists])

    elsif params[:playlists_radiostation_id].present?
      @playlists = Generalplaylist.where("radiostation_id = ?", "#{params[:playlists_radiostation_id]}").limit(params[:set_limit_playlists])

    elsif params[:set_counter_playlists].present?
      set_time_playlists
      @playlists = Generalplaylist.order(created_at: :DESC).limit(params[:set_limit_playlists])

    else
      if params[:set_limit_playlists].present?
        @playlists = Generalplaylist.order(created_at: :DESC).limit(params[:set_limit_playlists])
      else
        @playlists = Generalplaylist.order(created_at: :DESC).limit(5)
      end
    end

    @playlists.order!(created_at: :DESC)

  # Song search options
    if params[:search_top_song].present? && params[:songs_radiostation_id].present? && params[:set_counter_top_songs].present?
      set_time_songs
      @songs_counter = @songs_counter.joins(:song).where("radiostation_id = ? AND songs.fullname ILIKE ?", params[:songs_radiostation_id], "%#{params[:search_top_song]}%")
      group_songs

    elsif params[:search_top_song].present? && params[:songs_radiostation_id].present?
      radiostation = Radiostation.find(params[:songs_radiostation_id])
      @songs_counter = Generalplaylist.joins(:song).where("radiostation_id = ? AND songs.fullname ILIKE ?", radiostation.id, "%#{params[:search_top_song]}%").group(:song_id).count.sort_by{|song_id, counter| counter}.reverse.take(params[:set_limit_songs].to_i)

    elsif params[:search_top_song].present? && params[:set_counter_top_songs].present?
      set_time_songs
      @songs_counter = @songs_counter.joins(:song).where("songs.fullname ILIKE ?", "%#{params[:search_top_song]}%")
      group_songs

    elsif params[:songs_radiostation_id].present? && params[:set_counter_top_songs].present?
      set_time_songs
      @songs_counter = @songs_counter.where("radiostation_id = ?", params[:songs_radiostation_id])
      group_songs

    elsif params[:search_top_song].present?
      @songs_counter = Generalplaylist.joins(:song).where("songs.fullname ILIKE ?", "%#{params[:search_top_song]}%").group(:song_id).count.sort_by{|song_id, counter| counter}.reverse.take(params[:set_limit_songs].to_i)

    elsif params[:songs_radiostation_id].present?
      radiostation = Radiostation.find(params[:songs_radiostation_id])
      @songs_counter = Generalplaylist.where("radiostation_id = ?", radiostation.id).group(:song_id).count.sort_by{|song_id, counter| counter}.reverse.take(params[:set_limit_songs].to_i)

    elsif params[:set_counter_top_songs].present?
      set_time_songs and group_songs

    else
      if params[:set_limit_songs].present?
        @songs_counter = Generalplaylist.group(:song_id).count.sort_by{|song_id, counter| counter}.reverse.take(params[:set_limit_songs].to_i)
      else
        @songs_counter = Generalplaylist.group(:song_id).count.sort_by{|song_id, counter| counter}.reverse.take(5)
      end
    end

    @set_counter_top_songs = params[:set_counter_top_songs]

  # Artist search options
    if params[:search_top_artist].present? && params[:artists_radiostation_id].present? && params[:set_counter_top_artists].present?
      set_time_artists
      @artists_counter = @artists_counter.joins(:artist).where('radiostation_id = ? AND artists.name ILIKE ?', params[:artists_radiostation_id], "%#{params[:search_top_artist]}%")
      group_artists


    elsif params[:search_top_artist].present? && params[:artists_radiostation_id].present?
      set_time_artists
      @artists_counter = @artists_counter.joins(:artist).where('artists.name ILIKE ?', "%#{params[:search_top_artist]}%")
      group_artists

    elsif params[:search_top_artist].present? && params[:set_counter_top_artists].present?
      set_time_artists
      @artists_counter = @artists_counter.joins(:artist).where('artists.name ILIKE ?', "%#{params[:search_top_artist]}%")
      group_artists

    elsif params[:artists_radiostation_id].present? && params[:set_counter_top_artists].present?
      set_time_artists
      @artists_counter = @artists_counter.where('radiostation_id = ?', params[:artists_radiostation_id])
      group_artists

    elsif params[:search_top_artist].present?
      @artists_counter = Generalplaylist.joins(:artist).where('artists.name ILIKE ?', "%#{params[:search_top_artist]}%").group(:artist_id).count.sort_by{|artist_id, counter| counter}.reverse.take(params[:set_limit_artists].to_i)

    elsif params[:artists_radiostation_id].present?
      radiostation = Radiostation.find(params[:artists_radiostation_id])
      @artists_counter = Generalplaylist.where('radiostation_id = ?', radiostation.id).group(:artist_id).count.sort_by{|artist_id, counter| counter}.reverse.take(params[:set_limit_artists].to_i)

    elsif params[:set_counter_top_artists].present?
      set_time_artists and group_artists

    else
      @artists_counter = if params[:set_limit_artists].present?
                           Generalplaylist.group(:artist_id).count.sort_by { |_artist_id, counter| counter }.reverse.take(params[:set_limit_artists].to_i)
                         else
                           Generalplaylist.group(:artist_id).count.sort_by { |_artist_id, counter| counter }.reverse.take(5)
                         end
    end

    @set_counter_top_artists = params[:set_counter_top_artists]

    @target = params[:target]

  end

  def set_time_playlists
    case params[:set_counter_playlists]
    when 'day'
      @playlists = @playlists.where!('generalplaylists.created_at > ?', 1.day.ago)
    when 'week'
      @playlists = @playlists.where!('generalplaylists.created_at > ?', 1.week.ago)
    when 'month'
      @playlists = @playlists.where!('generalplaylists.created_at > ?', 1.month.ago)
    when 'year'
      @playlists = @playlists.where!('generalplaylists.created_at > ?', 1.year.ago)
    when 'total'
      @playlists
    end
  end

  def set_time_songs
    case params[:set_counter_top_songs]
    when 'day'
      if @songs_counter.present?
        @songs_counter = @songs_counter.where('generalplaylists.created_at > ?', 1.day.ago)
      elsif @songs_counter.nil?
        @songs_counter = Generalplaylist.where('created_at > ?', 1.day.ago)
      end
    when 'week'
      if @songs_counter.present?
        @songs_counter = @songs_counter.where('generalplaylists.created_at > ?', 1.week.ago)
      elsif @songs_counter.nil?
        @songs_counter = Generalplaylist.where('created_at > ?', 1.week.ago)
      end
    when 'month'
      if @songs_counter.present?
        @songs_counter = @songs_counter.where('generalplaylists.created_at > ?', 1.month.ago)
      elsif @songs_counter.nil?
        @songs_counter = Generalplaylist.where('created_at > ?', 1.month.ago)
      end
    when 'year'
      if @songs_counter.present?
        @songs_counter = @songs_counter.where('generalplaylists.created_at > ?', 1.year.ago)
      elsif @songs_counter.nil?
        @songs_counter = Generalplaylist.where('created_at > ?', 1.year.ago)
      end
    when 'total'
      @songs_counter
    end
  end

  def set_time_artists
    case params[:set_counter_top_artists]
    when 'day'
      if @artists_counter.present?
        @artists_counter = @artists_counter.where('generalplaylists.created_at > ?', 1.day.ago)
      elsif @artists_counter.nil?
        @artists_counter = Generalplaylist.where('created_at > ?', 1.day.ago)
      end
    when 'week'
      if @artists_counter.present?
        @artists_counter = @artists_counter.where('generalplaylists.created_at > ?', 1.week.ago)
      elsif @artists_counter.nil?
        @artists_counter = Generalplaylist.where('created_at > ?', 1.week.ago)
      end
    when 'month'
      if @artists_counter.present?
        @artists_counter = @artists_counter.where('generalplaylists.created_at > ?', 1.month.ago)
      elsif @artists_counter.nil?
        @artists_counter = Generalplaylist.where('created_at > ?', 1.month.ago)
      end
    when 'year'
      if @artists_counter.present?
        @artists_counter = @artists_counter.where('generalplaylists.created_at > ?', 1.year.ago)
      elsif @artists_counter.nil?
        @artists_counter = Generalplaylist.where('created_at > ?', 1.year.ago)
      end
    when 'total'
      @artists_counter
    end
  end

  def group_songs
    @songs_counter = @songs_counter.group_by(&:song_id).map { |id, song| [id, song.count] }.sort_by { |song_id, counter| counter }.reverse.take(params[:set_limit_songs].to_i)
  end

  def group_artists
    @artists_counter = @artists_counter.group_by(&:artist_id).map {|id, artist| [id, artist.count]}.sort_by { |artist_id, counter| counter }.reverse.take(params[:set_limit_artists].to_i)
  end

end
