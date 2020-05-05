# frozen_string_literal: true

class SongsController < ApplicationController
  def index
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
        @songs_counter = Generalplaylist.group(:song_id).count.sort_by{ |song_id, counter| counter }.reverse.take(params[:set_limit_songs].to_i)
      else
        @songs_counter = Generalplaylist.group(:song_id).count.sort_by{ |song_id, counter| counter }.reverse.paginate(page: params[:page], per_page: 10)
      end
    end

    @set_counter_top_songs = params[:set_counter_top_songs]

    render json: @songs_counter.to_json
  end

  def show
    song = Song.find params[:id]
    render json: SongSerializer.new(song).serializable_hash.to_json
  end

  private

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

  def group_songs
    @songs_counter = @songs_counter.group_by(&:song_id).map { |id, song| [id, song.count] }.sort_by { |song_id, counter| counter }.reverse.take(params[:set_limit_songs].to_i)
  end
end
