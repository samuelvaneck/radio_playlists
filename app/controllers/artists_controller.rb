# frozen_string_literal: true

class ArtistsController < ApplicationController
  def index
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
                           Generalplaylist.group(:artist_id).count.sort_by { |_artist_id, counter| counter }.reverse.paginate(page: params[:page], per_page: 10)
                         end
    end

    @set_counter_top_artists = params[:set_counter_top_artists]

    render json: @artists_counter.to_json
  end

  def show
    artist = Artist.find params[:id]
    options = {}
    options[:include] = [:songs]
    render json: ArtistSerializer.new(artist).serializable_hash.to_json
  end

  private

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

  def group_artists
    @artists_counter = @artists_counter.group_by(&:artist_id).map {|id, artist| [id, artist.count]}.sort_by { |artist_id, counter| counter }.reverse.take(params[:set_limit_artists].to_i)
  end
end
