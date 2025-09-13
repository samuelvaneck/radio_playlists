# frozen_string_literal: true

require 'rails_helper'

describe Lastfm::TrackFinder do
  subject(:track_finder) { described_class.new }
  
  let(:artist_name) { 'The Beatles' }
  let(:track_name) { 'Hey Jude' }
  let(:limit) { 5 }
  let(:invalid_artist_name) { '' }
  let(:invalid_track_name) { '' }

  describe '#search', :use_vcr do
    subject(:search_result) { track_finder.search(artist_name, track_name, limit: limit) }

    context 'with valid parameters' do
      it 'returns parsed search results' do
        expect(search_result).to be_an(Array)
        expect(search_result).not_to be_empty
      end

      context 'when results are returned' do
        let(:first_result) { search_result.first }

        it 'includes expected fields' do
          expect(first_result).to include(:name, :artist, :url)
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
      context 'when artist_name is blank' do
        subject(:search_result) { track_finder.search(invalid_artist_name, track_name) }

        it 'returns nil' do
          expect(search_result).to be_nil
        end
      end

      context 'when track_name is blank' do
        subject(:search_result) { track_finder.search(artist_name, invalid_track_name) }

        it 'returns nil' do
          expect(search_result).to be_nil
        end
      end
    end
  end

  describe '#get_info', :use_vcr do
    subject(:track_info) { track_finder.get_info(artist_name, track_name) }

    context 'with valid parameters' do
      it 'returns detailed track information' do
        expect(track_info).to be_a(Hash)
      end

      it 'includes expected fields' do
        expect(track_info).to include(:name, :artist, :url)
        expect(track_info[:name]).to be_present
        expect(track_info[:artist]).to be_present
      end
    end

    context 'with missing parameters' do
      context 'when artist_name is blank' do
        subject(:track_info) { track_finder.get_info(invalid_artist_name, track_name) }

        it 'returns nil' do
          expect(track_info).to be_nil
        end
      end

      context 'when track_name is blank' do
        subject(:track_info) { track_finder.get_info(artist_name, invalid_track_name) }

        it 'returns nil' do
          expect(track_info).to be_nil
        end
      end
    end
  end

  describe '#get_similar', :use_vcr do
    subject(:similar_tracks) { track_finder.get_similar(artist_name, track_name, limit: limit) }

    context 'with valid parameters' do
      it 'returns similar tracks' do
        expect(similar_tracks).to be_an(Array)
      end

      context 'when similar tracks exist' do
        let(:first_similar) { similar_tracks.first }

        it 'includes expected fields' do
          if similar_tracks.any?
            expect(first_similar).to include(:name, :artist)
          end
        end
      end
    end
  end

  describe '#get_top_tags', :use_vcr do
    subject(:top_tags) { track_finder.get_top_tags(artist_name, track_name) }

    context 'with valid parameters' do
      it 'returns top tags for the track' do
        expect(top_tags).to be_an(Array)
      end

      context 'when tags exist' do
        let(:first_tag) { top_tags.first }

        it 'includes expected fields' do
          expect(first_tag).to include(:name)
        end
      end
    end
  end

  describe 'error handling' do
    let(:error_response) { double('response', status: 500, body: 'Server Error') }
    let(:connection_error) { Faraday::ConnectionFailed.new('Network error') }
    
    context 'when API returns error', real_http: true do
      before do
        WebMock.enable!
        stub_request(:get, /ws\.audioscrobbler\.com/)
          .to_return(status: 500, body: 'Server Error')
      end

      describe '#search' do
        subject(:search_result) { track_finder.search(artist_name, track_name) }

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with(/Last.fm API error/)
          search_result
        end

        it 'returns nil' do
          allow(Rails.logger).to receive(:error)
          expect(search_result).to be_nil
        end
      end

      describe '#get_info' do
        subject(:track_info) { track_finder.get_info(artist_name, track_name) }

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with(/Last.fm API error/)
          track_info
        end

        it 'returns nil' do
          allow(Rails.logger).to receive(:error)
          expect(track_info).to be_nil
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

      describe '#search' do
        subject(:search_result) { track_finder.search(artist_name, track_name) }

        it 'logs the connection error' do
          expect(Rails.logger).to receive(:error).with(/connection error/)
          search_result
        end

        it 'returns nil' do
          allow(Rails.logger).to receive(:error)
          expect(search_result).to be_nil
        end
      end

      describe '#get_info' do
        subject(:track_info) { track_finder.get_info(artist_name, track_name) }

        it 'logs the connection error' do
          expect(Rails.logger).to receive(:error).with(/connection error/)
          track_info
        end

        it 'returns nil' do
          allow(Rails.logger).to receive(:error)
          expect(track_info).to be_nil
        end
      end
    end
  end
end
