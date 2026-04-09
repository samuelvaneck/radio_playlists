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
      description_en: generate_description(:en),
      description_nl: generate_description(:nl),
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
    counts = song_counts_by_year
    return nil if counts.empty?

    total = counts.values.sum
    percentiles = weighted_percentiles(counts, total)
    decades = peak_decades(total)

    {
      from: percentiles[:p10],
      to: percentiles[:p90],
      median_year: percentiles[:p50],
      peak_decades: decades,
      era_description_en: era_description(decades, :en),
      era_description_nl: era_description(decades, :nl),
      total_songs_with_date: total
    }
  end

  def generate_description(locale = :en)
    @description_context ||= {
      energy: label_for_feature('energy', feature_average(:energy)),
      valence: label_for_feature('valence', feature_average(:valence)),
      dance: label_for_feature('danceability', feature_average(:danceability)),
      tempo_avg: feature_average(:tempo, column: :tempo),
      genres: top_genres(limit: 3).map { |g| g[:name] },
      year_range: release_year_range
    }

    locale == :nl ? build_description_nl : build_description_en
  end

  def build_description_en
    ctx = @description_context
    parts = []
    parts << "#{@radio_station.name} is a #{ctx[:energy]}, #{ctx[:valence]} station"
    parts << "playing #{ctx[:dance]}, #{tempo_label(ctx[:tempo_avg])} music"
    parts << "with a focus on #{ctx[:genres].join(', ')}" if ctx[:genres].any?
    parts << ctx[:year_range][:era_description_en] if ctx[:year_range]
    "#{parts.join(' ')}."
  end

  def build_description_nl
    ctx = @description_context
    energy_nl = { 'laid-back' => 'relaxed', 'moderate energy' => 'gematigd energiek',
                  'high-energy' => 'energiek' }.fetch(ctx[:energy], ctx[:energy])
    valence_nl = { 'moody and introspective' => 'sfeervol en introspectief', 'balanced mood' => 'evenwichtig',
                   'upbeat and positive' => 'vrolijk en positief' }.fetch(ctx[:valence], ctx[:valence])
    dance_nl = { 'less danceable' => 'minder dansbare', 'moderately danceable' => 'gematigd dansbare',
                 'very danceable' => 'zeer dansbare' }.fetch(ctx[:dance], ctx[:dance])
    tempo_nl = { 'slow-tempo' => 'langzame', 'mid-tempo' => 'mid-tempo', 'upbeat' => 'vlotte',
                 'fast-paced' => 'snelle' }.fetch(tempo_label(ctx[:tempo_avg]), tempo_label(ctx[:tempo_avg]))

    parts = []
    parts << "#{@radio_station.name} is een #{energy_nl}, #{valence_nl} station"
    parts << "met #{dance_nl}, #{tempo_nl} muziek"
    parts << "gericht op #{ctx[:genres].join(', ')}" if ctx[:genres].any?
    parts << ctx[:year_range][:era_description_nl] if ctx[:year_range]
    "#{parts.join(' ')}."
  end

  def sample_size
    profiles_scope.count
  end

  def song_counts_by_year
    @song_counts_by_year ||= Song.joins(:air_plays)
                               .where(air_plays: { radio_station_id: @radio_station.id, broadcasted_at: @start_time..@end_time })
                               .where.not(release_date: nil)
                               .group(Arel.sql('EXTRACT(YEAR FROM songs.release_date)::integer'))
                               .count
                               .sort_by(&:first)
                               .to_h
  end

  def weighted_percentiles(counts, total)
    targets = { p10: 0.10, p25: 0.25, p50: 0.50, p75: 0.75, p90: 0.90 }
    result = {}
    cumulative = 0

    counts.each do |year, count|
      cumulative += count
      pct = cumulative.to_f / total
      targets.each do |key, threshold|
        result[key] ||= year if pct >= threshold
      end
    end

    result
  end

  def decade_totals
    @decade_totals ||= song_counts_by_year.each_with_object(Hash.new(0)) do |(year, count), h|
      h[(year / 10) * 10] += count
    end
  end

  def peak_decades(total)
    decade_totals
      .select { |_, count| count.to_f / total >= 0.15 }
      .sort_by { |_, count| -count }
      .map(&:first)
      .sort
  end

  def era_description(decades, locale)
    return '' if decades.empty?

    decade_labels = decades.map { |d| "#{d}s" }
    current_decade = (Time.current.year / 10) * 10

    if decades.size == 1
      single_decade_text(decade_labels.first, locale)
    elsif dominant_recent_decade?(decades, current_decade)
      recent_dominant_text(locale)
    elsif mixed_era?(decades, current_decade)
      core_labels = decades.select { |d| d < current_decade - 10 }.map { |d| "#{d}s" }
      mixed_era_text(core_labels, locale)
    else
      multi_decade_text(decade_labels, locale)
    end
  end

  def dominant_recent_decade?(decades, current_decade)
    total = song_counts_by_year.values.sum
    return false unless total.positive?

    dominant = decades.max_by { |d| decade_totals[d] || 0 }
    dominant_share = (decade_totals[dominant] || 0).to_f / total
    dominant_share >= 0.60 && dominant >= current_decade
  end

  def mixed_era?(decades, current_decade)
    has_recent = decades.any? { |d| d >= current_decade - 10 }
    core_decades = decades.reject { |d| d >= current_decade - 10 }
    core_decades.any? && has_recent && core_decades != decades
  end

  def single_decade_text(decade_label, locale)
    locale == :nl ? "voornamelijk uit de jaren #{decade_label.delete_suffix('s')}" : "primarily from the #{decade_label}"
  end

  def mixed_era_text(core_labels, locale)
    if locale == :nl
      "voornamelijk uit de jaren #{core_labels.join(' en ')}, aangevuld met recente muziek"
    else
      "primarily from the #{core_labels.join(' and ')}, complemented by recent releases"
    end
  end

  def multi_decade_text(decade_labels, locale)
    locale == :nl ? "voornamelijk uit de jaren #{decade_labels.join(' en ')}" : "primarily from the #{decade_labels.join(' and ')}"
  end

  def recent_dominant_text(locale)
    locale == :nl ? 'voornamelijk uit de afgelopen jaren' : 'predominantly from recent years'
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
