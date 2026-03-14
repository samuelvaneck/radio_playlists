# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'data_repair:cleanup_orphaned_artists' do # rubocop:disable RSpec/DescribeClass
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    Rails.application.load_tasks
  end

  after do
    Rake::Task['data_repair:cleanup_orphaned_artists'].reenable
    Rake::Task['data_repair:cleanup_orphaned_artists_dry_run'].reenable
  end

  describe 'cleanup_orphaned_artists' do
    context 'when there are orphaned artists' do
      let!(:orphaned_artist) { create(:artist, name: 'Orphaned Artist') }
      let!(:another_orphaned_artist) { create(:artist, name: 'Another Orphaned') }
      let!(:artist_with_song) { create(:artist, name: 'Has Songs') }

      before { create(:song, artists: [artist_with_song]) }

      it 'destroys artists without songs', :aggregate_failures do
        expect { Rake::Task['data_repair:cleanup_orphaned_artists'].invoke }
          .to change(Artist, :count).by(-2)

        expect(Artist.find_by(id: orphaned_artist.id)).to be_nil
        expect(Artist.find_by(id: another_orphaned_artist.id)).to be_nil
        expect(Artist.find_by(id: artist_with_song.id)).to be_present
      end
    end

    context 'when there are no orphaned artists' do
      let!(:artist_with_song) { create(:artist, name: 'Has Songs') }

      before { create(:song, artists: [artist_with_song]) }

      it 'reports no orphaned artists found' do
        expect { Rake::Task['data_repair:cleanup_orphaned_artists'].invoke }
          .to output(/No orphaned artists found/).to_stdout
      end
    end
  end

  describe 'cleanup_orphaned_artists_dry_run' do
    context 'when there are orphaned artists' do
      let!(:orphaned_artist) { create(:artist, name: 'Orphaned Artist') }
      let!(:artist_with_song) { create(:artist, name: 'Has Songs') }

      before { create(:song, artists: [artist_with_song]) }

      it 'lists orphaned artists without destroying them', :aggregate_failures do
        expect { Rake::Task['data_repair:cleanup_orphaned_artists_dry_run'].invoke }
          .to output(/Found 1 orphaned artists/).to_stdout

        expect(Artist.find_by(id: orphaned_artist.id)).to be_present
      end
    end

    context 'when there are no orphaned artists' do
      let!(:artist_with_song) { create(:artist, name: 'Has Songs') }

      before { create(:song, artists: [artist_with_song]) }

      it 'reports no orphaned artists found' do
        expect { Rake::Task['data_repair:cleanup_orphaned_artists_dry_run'].invoke }
          .to output(/No orphaned artists found/).to_stdout
      end
    end
  end
end
