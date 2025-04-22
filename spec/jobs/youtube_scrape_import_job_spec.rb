# frozen_string_literal: true

require 'rails_helper'

describe YoutubeScrapeImportJob, type: :job do
  subject(:perform_job) { job.perform }

  let(:job) { described_class.new }
  let(:artist) { create(:artist, name: 'Artist Name') }
  let!(:song) { create(:song, title: 'Song Title', artists: [artist], id_on_youtube: nil) }
  let(:response_data) do
    {
      'played_tracks' => [
        {
          'artist' => { 'name' => 'Artist Name' },
          'title' => 'Song Title',
          'videos' => [{ 'type' => 'youtube', 'id' => 'youtube123' }]
        }
      ]
    }.with_indifferent_access
  end

  before do
    allow(job).to receive(:make_request).and_return(response_data)
  end

  describe '#perform' do
    context 'when the response contains valid data' do
      it 'updates the song with the id_on_youtube' do
        expect do
          perform_job
        end.to change { song.reload.id_on_youtube }.from(nil).to('youtube123')
      end
    end

    context 'when the response is blank' do
      let(:response_data) { nil }

      it 'does not update the song' do
        expect { perform_job }.not_to(change { song.reload.id_on_youtube })
      end
    end

    context 'when the id_on_youtube is blank' do
      let(:response_data) do
        {
          'played_tracks' => [
            {
              'artist' => { 'name' => 'Artist Name' },
              'title' => 'Song Title',
              'videos' => []
            }
          ]
        }.with_indifferent_access
      end

      it 'does not update the song' do
        expect { perform_job }.not_to(change { song.reload.id_on_youtube })
      end
    end
  end
end
