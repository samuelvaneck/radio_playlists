# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArtistTimelineEnrichmentBatchJob do
  describe '#perform' do
    it 'delegates to ArtistTimelineEnrichmentJob.enqueue_stale' do
      allow(ArtistTimelineEnrichmentJob).to receive(:enqueue_stale)
      described_class.new.perform
      expect(ArtistTimelineEnrichmentJob).to have_received(:enqueue_stale)
    end
  end
end
