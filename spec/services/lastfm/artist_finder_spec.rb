# frozen_string_literal: true

require 'rails_helper'

describe Lastfm::ArtistFinder do
  subject(:artist_finder) { described_class.new }
  
  let(:artist_name) { 'The Beatles' }
  let(:invalid_artist_name) { '' }
  let(:limit) { 5 }

  describe '#search', :use_vcr do
    subject(:search_result) { artist_finder.search(artist_name, limit: limit) }

    context 'with valid parameters' do
      it 'returns parsed search results' do
        expect(search_result).to be_an(Array)
        expect(search_result).not_to be_empty
      end

      context 'when results are returned' do
        let(:first_result) { search_result.first }

        it 'includes expected fields' do
          expect(first_result).to include(:name, :url)
        end
      end

      context 'with custom limit' do
        let(:limit) { 3 }

        it 'respects the limit parameter' do
          expect(search_result).to be_an(Array)
          expect(search_result.size).to be <= limit
        end
      end
    end

    context 'with missing parameters' do
      subject(:search_result) { artist_finder.search(invalid_artist_name) }

      it 'returns nil when artist_name is blank' do
        expect(search_result).to be_nil
      end
    end
  end

  describe '#get_info', :use_vcr do
    subject(:artist_info) { artist_finder.get_info(artist_name) }

    context 'with valid parameters' do
      it 'returns detailed artist information' do
        expect(artist_info).to be_a(Hash)
      end

      it 'includes expected fields' do
        expect(artist_info).to include(:name, :url)
        expect(artist_info[:name]).to be_present
      end
    end

    context 'with missing parameters' do
      subject(:artist_info) { artist_finder.get_info(invalid_artist_name) }

      it 'returns nil when artist_name is blank' do
        expect(artist_info).to be_nil
      end
    end
  end

  describe '#get_similar', :use_vcr do
    subject(:similar_artists) { artist_finder.get_similar(artist_name, limit: limit) }

    context 'with valid parameters' do
      it 'returns similar artists' do
        expect(similar_artists).to be_an(Array)
      end

      context 'when similar artists exist' do
        let(:first_similar) { similar_artists.first }

        it 'includes expected fields' do
          if similar_artists.any?
            expect(first_similar).to include(:name)
          end
        end
      end
    end
  end

  describe '#get_top_tracks', :use_vcr do
    subject(:top_tracks) { artist_finder.get_top_tracks(artist_name, limit: limit) }

    context 'with valid parameters' do
      it 'returns top tracks' do
        expect(top_tracks).to be_an(Array)
      end

      context 'when top tracks exist' do
        let(:first_track) { top_tracks.first }

        it 'includes expected fields' do
          if top_tracks.any?
            expect(first_track).to include(:name)
          end
        end
      end
    end
  end

  describe '#get_top_albums', :use_vcr do
    subject(:top_albums) { artist_finder.get_top_albums(artist_name, limit: limit) }

    context 'with valid parameters' do
      it 'returns top albums' do
        expect(top_albums).to be_an(Array)
      end

      context 'when top albums exist' do
        let(:first_album) { top_albums.first }

        it 'includes expected fields' do
          if top_albums.any?
            expect(first_album).to include(:name)
          end
        end
      end
    end
  end

  describe '#get_top_tags', :use_vcr do
    subject(:top_tags) { artist_finder.get_top_tags(artist_name) }

    context 'with valid parameters' do
      it 'returns top tags for the artist' do
        expect(top_tags).to be_an(Array)
      end

      context 'when tags exist' do
        let(:first_tag) { top_tags.first }

        it 'includes expected fields' do
          if top_tags.any?
            expect(first_tag).to include(:name)
          end
        end
      end
    end
  end

  describe 'error handling' do
    let(:error_response) { double('response', status: 500, body: 'Server Error') }
    let(:connection_error) { Faraday::ConnectionFailed.new('Network error') }
    let(:logger_double) { instance_double(ActiveSupport::Logger) }

    before do
      allow(Rails).to receive(:logger).and_return(logger_double)
      allow(logger_double).to receive(:error)
    end

    context 'when API returns error', real_http: true do
      before do
        WebMock.enable!
        stub_request(:get, /ws\.audioscrobbler\.com/)
          .to_return(status: 500, body: 'Server Error')
      end

      describe '#search' do
        subject(:search_result) { artist_finder.search(artist_name) }

        it 'logs the error' do
          expect(logger_double).to receive(:error).with(/Last.fm API error/)
          search_result
        end

        it 'returns nil' do
          expect(search_result).to be_nil
        end
      end

      describe '#get_info' do
        subject(:artist_info) { artist_finder.get_info(artist_name) }

        it 'logs the error' do
          expect(logger_double).to receive(:error).with(/Last.fm API error/)
          artist_info
        end

        it 'returns nil' do
          expect(artist_info).to be_nil
        end
      end
    end

    context 'when network error occurs', real_http: true do
      before do
        WebMock.disable!
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(connection_error)
      end

      after do
        WebMock.enable!
      end

      shared_examples 'handles network errors' do |method_name|
        it 'logs the connection error' do
          expect(logger_double).to receive(:error).with(/connection error/)
          subject
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      describe '#search' do
        subject(:search_result) { artist_finder.search(artist_name) }
        include_examples 'handles network errors', :search
      end

      describe '#get_info' do
        subject(:artist_info) { artist_finder.get_info(artist_name) }
        include_examples 'handles network errors', :get_info
      end

      describe '#get_similar' do
        subject(:similar_artists) { artist_finder.get_similar(artist_name) }
        include_examples 'handles network errors', :get_similar
      end

      describe '#get_top_tracks' do
        subject(:top_tracks) { artist_finder.get_top_tracks(artist_name) }
        include_examples 'handles network errors', :get_top_tracks
      end

      describe '#get_top_albums' do
        subject(:top_albums) { artist_finder.get_top_albums(artist_name) }
        include_examples 'handles network errors', :get_top_albums
      end

      describe '#get_top_tags' do
        subject(:top_tags) { artist_finder.get_top_tags(artist_name) }
        include_examples 'handles network errors', :get_top_tags
      end
    end
  end
end
