# frozen_string_literal: true

namespace :lyrics do
  desc 'Enqueue LyricsEnrichmentJob for recently-played songs missing or stale lyrics. ' \
       'Requires LYRICS_ENRICHMENT_ENABLED=true. Usage: rake lyrics:backfill'
  task backfill: :environment do
    unless LyricsEnrichmentJob.enabled?
      $stdout.puts 'Skipping: LYRICS_ENRICHMENT_ENABLED is not set to true'
      next
    end

    count = LyricsEnrichmentJob.enrichable_songs.count
    $stdout.puts "Enqueuing lyrics enrichment for #{count} songs..."
    LyricsEnrichmentJob.enqueue_all
    $stdout.puts 'Done.'
  end

  desc 'Audit production lyric themes and report any tags missing from the EN→NL ' \
       'translator map. Output is grouped by frequency. Usage: rake lyrics:audit_themes'
  task audit_themes: :environment do
    counts = Hash.new(0)
    Lyric.where.not(themes: []).find_each do |lyric|
      lyric.themes.each { |t| counts[t.to_s.downcase.strip] += 1 if t.present? }
    end

    unmapped = counts.reject { |theme, _| Lyrics::ThemeTranslator.mapped?(theme) }
    if unmapped.empty?
      $stdout.puts "All #{counts.size} distinct themes are mapped."
      next
    end

    $stdout.puts "Found #{unmapped.size} unmapped themes (out of #{counts.size} total):"
    unmapped.sort_by { |_, count| -count }.each do |theme, count|
      $stdout.puts "  #{theme.inspect} — #{count} lyric(s)"
    end
  end
end
