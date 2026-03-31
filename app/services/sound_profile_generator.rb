# frozen_string_literal: true

class SoundProfileGenerator
  FEATURE_LABELS = {
    energy: { low: 'laid-back', mid: 'moderate energy', high: 'high-energy' },
    danceability: { low: 'less danceable', mid: 'moderately danceable', high: 'very danceable' },
    valence: { low: 'moody and introspective', mid: 'balanced mood', high: 'upbeat and positive' },
    acousticness: { low: 'mostly produced', mid: 'mix of acoustic and produced', high: 'acoustic-leaning' },
    speechiness: { low: 'mostly singing', mid: 'some spoken content', high: 'speech-heavy' },
    instrumentalness: { low: 'vocal-driven', mid: 'some instrumental tracks', high: 'mostly instrumental' },
    liveness: { low: 'studio recordings', mid: 'some live feel', high: 'live recordings' }
  }.freeze

  TEMPO_LABELS = {
    slow: { range: 0..89, label: 'slow-tempo' },
    mid: { range: 90..119, label: 'mid-tempo' },
    upbeat: { range: 120..139, label: 'upbeat' },
    fast: { range: 140..Float::INFINITY, label: 'fast-paced' }
  }.freeze

  def initialize(radio_station:, start_time: nil, end_time: nil)
    @radio_station = radio_station
    @start_time = start_time || 4.weeks.ago
    @end_time = end_time || Time.current
  end

  def generate
    {
      radio_station: { id: @radio_station.id, name: @radio_station.name, slug: @radio_station.slug },
      period: { start_time: @start_time.iso8601, end_time: @end_time.iso8601 },
      audio_features: audio_feature_summaries,
      tempo: tempo_summary,
      top_genres: top_genres,
      top_tags: top_tags,
      release_decade_distribution: release_decade_distribution,
      release_year_range: release_year_range,
      description: generate_description,
      sample_size: sample_size
    }
  end

  private

  def audio_feature_summaries
    MusicProfile::AUDIO_FEATURES.to_h do |feature|
      avg = feature_average(feature)
      [feature, { average: avg, label: label_for_feature(feature, avg) }]
    end
  end

  def tempo_summary
    avg = feature_average(:tempo, column: :tempo)
    { average: avg, label: tempo_label(avg) }
  end

  def label_for_feature(feature, value)
    return 'unknown' if value.nil? || value.zero?

    labels = FEATURE_LABELS[feature.to_sym]
    return 'unknown' unless labels

    threshold = MusicProfile::HIGH_VALUE_THRESHOLDS[feature.to_sym] || 0.5
    low_threshold = threshold * 0.6

    if value <= low_threshold
      labels[:low]
    elsif value <= threshold
      labels[:mid]
    else
      labels[:high]
    end
  end

  def tempo_label(value)
    return 'unknown' if value.nil? || value.zero?

    TEMPO_LABELS.each_value do |config|
      return config[:label] if config[:range].cover?(value.to_i)
    end
    'unknown'
  end

  def feature_average(feature, column: feature)
    profiles_scope.average(column)&.round(3).to_f
  end

  def top_genres(limit: 10)
    Artist.joins(:air_plays)
      .where(air_plays: { radio_station_id: @radio_station.id, broadcasted_at: @start_time..@end_time })
      .where.not(genres: nil).where.not(genres: [])
      .pluck(:genres)
      .flatten
      .tally
      .sort_by { |_, count| -count }
      .first(limit)
      .map { |genre, count| { name: genre, count: count } }
  end

  def top_tags(limit: 10)
    Song.joins(:air_plays)
      .where(air_plays: { radio_station_id: @radio_station.id, broadcasted_at: @start_time..@end_time })
      .where.not(lastfm_tags: nil).where.not(lastfm_tags: [])
      .pluck(:lastfm_tags)
      .flatten
      .tally
      .sort_by { |_, count| -count }
      .first(limit)
      .map { |tag, count| { name: tag, count: count } }
  end

  def release_decade_distribution
    Song.joins(:air_plays)
      .where(air_plays: { radio_station_id: @radio_station.id, broadcasted_at: @start_time..@end_time })
      .where.not(release_date: nil)
      .group(Arel.sql('(EXTRACT(YEAR FROM songs.release_date)::integer / 10) * 10'))
      .count
      .sort_by { |decade, _| decade }
      .map { |decade, count| { decade: "#{decade}s", count: count } }
  end

  def release_year_range
    years = release_years_sorted
    return nil if years.empty?

    # Trim 10% from each side to get the middle 80%
    trim_count = (years.size * 0.1).floor
    trimmed = years[trim_count..-(trim_count + 1)] || years
    trimmed = years if trimmed.empty?

    {
      from: trimmed.first,
      to: trimmed.last,
      label: "80% of songs are from #{trimmed.first}–#{trimmed.last}",
      total_songs_with_date: years.size
    }
  end

  def generate_description
    parts = []

    energy_label = label_for_feature('energy', feature_average(:energy))
    valence_label = label_for_feature('valence', feature_average(:valence))
    dance_label = label_for_feature('danceability', feature_average(:danceability))
    tempo_avg = feature_average(:tempo, column: :tempo)

    parts << "#{@radio_station.name} is a #{energy_label}, #{valence_label} station"
    parts << "playing #{dance_label}, #{tempo_label(tempo_avg)} music"

    top_genre_names = top_genres(limit: 3).map { |g| g[:name] }
    parts << "with a focus on #{top_genre_names.join(', ')}" if top_genre_names.any?

    year_range = release_year_range
    parts << "mostly from #{year_range[:from]}–#{year_range[:to]}" if year_range

    "#{parts.join(' ')}."
  end

  def sample_size
    profiles_scope.count
  end

  def release_years_sorted
    @release_years_sorted ||= Song.joins(:air_plays)
                                .where(air_plays: { radio_station_id: @radio_station.id, broadcasted_at: @start_time..@end_time })
                                .where.not(release_date: nil)
                                .distinct
                                .pluck(Arel.sql('EXTRACT(YEAR FROM songs.release_date)::integer'))
                                .compact
                                .sort
  end

  def profiles_scope
    @profiles_scope ||= MusicProfile
                          .joins(song: :air_plays)
                          .where(air_plays: {
                                   radio_station_id: @radio_station.id,
                                   broadcasted_at: @start_time..@end_time
                                 })
                          .distinct
  end
end
