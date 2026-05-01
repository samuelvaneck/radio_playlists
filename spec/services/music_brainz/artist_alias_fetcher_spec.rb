# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MusicBrainz::ArtistAliasFetcher, type: :service do
  let(:artist) { create(:artist, name: 'P!nk') }
  let(:mbid) { 'f4d5cc07-3bc9-4836-9b15-88a08359bc63' }
  let(:fetcher) { described_class.new(artist) }

  before { allow(fetcher).to receive(:sleep) }

  describe '#call' do
    context 'when artist already has id_on_musicbrainz' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}})
          .to_return(status: 200, body: lookup_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      let(:lookup_response) do
        {
          'id' => mbid,
          'name' => 'P!nk',
          'aliases' => [
            { 'name' => 'Pink', 'type' => 'Artist name', 'locale' => nil },
            { 'name' => 'Alecia Beth Moore', 'type' => 'Legal name', 'locale' => nil },
            { 'name' => 'P.nk', 'type' => 'Search hint', 'locale' => nil },
            { 'name' => 'ピンク', 'type' => 'Artist name', 'locale' => 'ja' }
          ],
          'relations' => []
        }
      end

      it 'persists filtered aliases and the canonical name', :aggregate_failures do
        fetcher.()
        artist.reload
        expect(artist.aka_names).to contain_exactly('P!nk', 'Pink', 'Alecia Beth Moore', 'P.nk')
        expect(artist.aka_names_checked_at).to be_within(5.seconds).of(Time.current)
      end

      it 'skips aliases with foreign locales' do
        fetcher.()
        expect(artist.reload.aka_names).not_to include('ピンク')
      end

      it 'skips untyped alias entries' do
        lookup_response['aliases'] << { 'name' => 'Pinkk typo', 'type' => nil, 'locale' => nil }
        fetcher.()
        expect(artist.reload.aka_names).not_to include('Pinkk typo')
      end
    end

    context 'when artist needs MBID lookup and the top match passes validation' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/artist\?}).to_return(
          status: 200, body: search_response.to_json, headers: { 'Content-Type' => 'application/json' }
        )
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}}).to_return(
          status: 200, body: { 'id' => mbid, 'name' => 'P!nk', 'aliases' => [], 'relations' => [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      let(:search_response) do
        { 'artists' => [{ 'id' => mbid, 'name' => 'P!nk', 'score' => 100 }] }
      end

      it 'persists the discovered MBID' do
        fetcher.()
        expect(artist.reload.id_on_musicbrainz).to eq(mbid)
      end
    end

    context 'when search score is below threshold' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/artist\?}).to_return(
          status: 200,
          body: { 'artists' => [{ 'id' => mbid, 'name' => 'P!nk', 'score' => 80 }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'leaves the artist unchanged', :aggregate_failures do
        expect(fetcher.()).to be(false)
        expect(artist.reload.id_on_musicbrainz).to be_nil
        expect(artist.aka_names).to be_empty
      end
    end

    context 'when search returns a name that is not similar enough' do
      before do
        stub_request(:get, %r{musicbrainz.org/ws/2/artist\?}).to_return(
          status: 200,
          body: { 'artists' => [{ 'id' => mbid, 'name' => 'Pink Martini', 'score' => 100 }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'rejects the candidate' do
        expect(fetcher.()).to be(false)
      end
    end

    context 'when artist has artist-rename relations' do
      let(:artist) { create(:artist, name: "Terence Trent D'Arby") }
      let(:related_mbid) { '66e8f2b9-69c3-4ded-8095-b65657940473' }
      let(:lookup_with_rename) do
        {
          'id' => mbid,
          'name' => "Terence Trent D'Arby",
          'aliases' => [{ 'name' => "Terence Trent D'Arby", 'type' => 'Artist name', 'locale' => nil }],
          'relations' => [{ 'type' => 'artist rename', 'artist' => { 'id' => related_mbid, 'name' => 'Sananda Maitreya' } }]
        }
      end
      let(:rename_target_lookup) do
        {
          'id' => related_mbid,
          'name' => 'Sananda Maitreya',
          'aliases' => [{ 'name' => 'Sananda Francesco Maitreya', 'type' => 'Legal name', 'locale' => nil }],
          'relations' => []
        }
      end

      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}}).to_return(
          status: 200, body: lookup_with_rename.to_json, headers: { 'Content-Type' => 'application/json' }
        )
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{related_mbid}}).to_return(
          status: 200, body: rename_target_lookup.to_json, headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'merges names from the rename target into aka_names', :aggregate_failures do
        fetcher.()
        names = artist.reload.aka_names
        expect(names).to include("Terence Trent D'Arby", 'Sananda Maitreya', 'Sananda Francesco Maitreya')
      end
    end

    context 'when the lookup API returns an error' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}}).to_return(status: 503, body: 'Service Unavailable')
      end

      it 'returns false and leaves aka_names empty', :aggregate_failures do
        expect(fetcher.()).to be(false)
        expect(artist.reload.aka_names).to be_empty
      end
    end

    context 'when the lookup response is invalid JSON' do
      before do
        artist.update!(id_on_musicbrainz: mbid)
        stub_request(:get, %r{musicbrainz.org/ws/2/artist/#{mbid}}).to_return(
          status: 200, body: 'not json', headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'returns false' do
        expect(fetcher.()).to be(false)
      end
    end
  end
end
