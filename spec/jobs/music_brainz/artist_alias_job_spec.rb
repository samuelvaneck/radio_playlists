# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MusicBrainz::ArtistAliasJob do
  describe '#perform' do
    let(:job) { described_class.new }

    context 'when artist exists' do
      let(:artist) { create(:artist, name: 'P!nk') }
      let(:fetcher) { instance_double(MusicBrainz::ArtistAliasFetcher, call: true) }

      before { allow(MusicBrainz::ArtistAliasFetcher).to receive(:new).and_return(fetcher) }

      it 'invokes the alias fetcher for the artist', :aggregate_failures do
        job.perform(artist.id)
        expect(MusicBrainz::ArtistAliasFetcher).to have_received(:new).with(an_object_having_attributes(id: artist.id))
        expect(fetcher).to have_received(:call)
      end
    end

    context 'when artist does not exist' do
      before { allow(MusicBrainz::ArtistAliasFetcher).to receive(:new) }

      it 'does not raise and does not invoke the fetcher', :aggregate_failures do
        expect { job.perform(999_999) }.not_to raise_error
        expect(MusicBrainz::ArtistAliasFetcher).not_to have_received(:new)
      end
    end
  end
end
