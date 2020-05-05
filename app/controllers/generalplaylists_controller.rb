# frozen_string_literal: true

class GeneralplaylistsController < ApplicationController
  respond_to :html, :js

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

  

    @target = params[:target]

    @playlists = @playlists.paginate(page: params[:page], per_page: 10)

    respond_with GeneralplaylistSerializer.new(@playlists).serializable_hash.to_json
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
end
