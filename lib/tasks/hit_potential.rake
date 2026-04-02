# frozen_string_literal: true

namespace :hit_potential do
  desc 'Backfill hit_potential_score for songs with music profiles. Usage: rake hit_potential:backfill'
  task backfill: :environment do
    songs = Song.joins(:music_profile).where(hit_potential_score: nil)
    total = songs.count
    puts "Backfilling hit_potential_score for #{total} songs..."

    updated = 0
    songs.find_each do |song|
      score = HitPotentialCalculator.new(song.music_profile).calculate
      next if score.blank?

      song.update_column(:hit_potential_score, score) # rubocop:disable Rails/SkipsModelValidations
      updated += 1
      print "\r#{updated}/#{total} updated" if (updated % 100).zero?
    end

    puts "\nDone. Updated #{updated} songs."
  end
end
