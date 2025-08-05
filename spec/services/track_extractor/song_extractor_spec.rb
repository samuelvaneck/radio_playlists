# frozen_string_literal: true
require 'ostruct'

require 'rails_helper'

describe TrackExtractor::SongExtractor do
  subject { described_class.new(played_song:, track:, artists: [artist]) }

  let(:artist) { create(:artist) }
  let(:track) do
    OpenStruct.new(
      title: 'Test Song',
      id: 'spotify123',
      isrc: 'ISRC123',
      spotify_song_url: 'https://open.spotify.com/track/spotify123',
      spotify_artwork_url: 'https://i.scdn.co/image/artwork',
      spotify_preview_url: 'https://p.scdn.co/mp3-preview/preview',
      release_date: '2023-01-01'
    )
  end
  let(:played_song) do
    OpenStruct.new(
      title: 'Test Song',
      artist_name: 'Test Artist',
      spotify_url: 'https://open.spotify.com/track/spotify123',
      isrc_code: 'ISRC123'
    )
  end

  describe '#extract' do
    let(:song) { subject.extract }

    context 'when song does not exist' do
      it 'creates a new song with correct attributes' do
        expect(song).to be_a(Song)
        expect(song.title).to eq('Test Song')
        expect(song.id_on_spotify).to eq('spotify123')
        expect(song.isrc).to eq('ISRC123')
        expect(song.spotify_preview_url).to eq('https://p.scdn.co/mp3-preview/preview')
        expect(song.artists).to include(artist)
        expect(song.release_date).to eq(Date.parse('2023-01-01'))
      end
    end

    context 'when song exists' do
      let!(:existing_song) do
        create(:song,
               title: 'Test Song',
               id_on_spotify: 'spotify123',
               artists: [artist],
               spotify_preview_url: nil,
               release_date: nil)
      end

      it 'finds the existing song' do
        expect(song).to eq(existing_song)
      end

      it 'updates preview url if missing' do
        expect {
          subject.extract
          existing_song.reload
        }.to change(existing_song, :spotify_preview_url).to('https://p.scdn.co/mp3-preview/preview')
      end

      it 'updates the release date if missing' do
        expect {
          subject.extract
          existing_song.reload
        }.to change(existing_song, :release_date).to(Date.parse('2023-01-01'))
      end
    end
  end
end
