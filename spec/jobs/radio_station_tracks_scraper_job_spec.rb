# frozen_string_literal: true

require 'rails_helper'

describe RadioStationTracksScraperJob, :use_vcr, type: :job do
  subject(:perform_job) { job.perform }

  let(:job) { described_class.new }
  let(:artist) { create(:artist, name: 'Ed Sheeran') }
  let!(:song) { create(:song, title: 'Sapphire', artists: [artist], id_on_youtube: nil) }
  let(:response_data) do
    JSON.parse(file_fixture('qmusic_api_response.json').read).with_indifferent_access
  end

  before do
    allow(job).to receive(:response).and_return(response_data)
  end

  describe '#perform' do
    context 'when the response contains valid data' do
      before do
        allow(song).to receive(:should_update_youtube?).and_return(false)
      end

      it 'updates the song with the id_on_youtube' do
        perform_job

        expect(song.reload.id_on_youtube).to eq('JgDNFQ2RaLQ')
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

    context 'when the artist website URL is present' do
      it 'updates the artist website_url with the website URL' do
        expect do
          perform_job
          artist.reload
        end.to change(artist, :website_url).from(nil).to('http://edsheeran.com/')
      end
    end

    context 'when the instagram URL is present' do
      it 'updates the artist instagram_url with the instagram URL' do
        expect do
          perform_job
          artist.reload
        end.to change(artist, :instagram_url).from(nil).to('https://instagram.com/teddysphotos')
      end
    end
  end
end
