# frozen_string_literal: true

describe Api::V1::ArtistsController do
  let(:artist_one) { create :artist }
  let(:song_one) { create :song, artists: [artist_one] }
  let(:artist_two) { create :artist }
  let(:song_two) { create :song, artists: [artist_two] }
  let(:artist_three) { create :artist }
  let(:song_three) { create :song, artists: [artist_three] }
  let(:radio_station_one) { create :radio_station }
  let(:radio_station_two) { create :radio_station }
  let(:radio_station_three) { create :radio_station }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('LASTFM_API_KEY', nil).and_return('test_api_key')

    create(:air_play, song: song_one, radio_station: radio_station_one)
    create(:air_play, song: song_two, radio_station: radio_station_two)
    create_list(:air_play, 5, song: song_three, radio_station: radio_station_three)
  end

  describe 'GET #index' do
    subject(:get_index) { get :index, params: { format: :json } }

    context 'with no search params' do
      it 'returns status OK/200' do
        get_index
        expect(response.status).to eq 200
      end

      it 'returns all the air plays artists' do
        get_index
        expect(json[:data].count).to eq(3)
      end
    end

    context 'with search params' do
      it 'only returns the search artist' do
        get :index, params: { format: :json, search_term: artist_one.name }

        expect(json[:data].map { |artist| artist[:id] }).to contain_exactly(artist_one.id.to_s)
      end
    end

    context 'when filtering by radio station' do
      it 'only returns the artists that are played by the radio station' do
        get :index, params: { format: :json, radio_station_ids: [radio_station_one.id] }

        expect(json[:data].map { |artist| artist[:id] }).to contain_exactly(artist_one.id.to_s)
      end
    end

    context 'with lastfm_tags' do
      let(:artist_with_tags) { create :artist, lastfm_tags: %w[rock pop] }
      let(:song_with_tags) { create :song, artists: [artist_with_tags] }

      before do
        create(:air_play, song: song_with_tags, radio_station: radio_station_one)
      end

      it 'returns lastfm_tags in the response' do
        get :index, params: { format: :json }

        artist_data = json[:data].find { |a| a[:id] == artist_with_tags.id.to_s }
        expect(artist_data[:attributes][:lastfm_tags]).to eq(%w[rock pop])
      end
    end
  end

  describe 'GET #bio' do
    let(:artist) { create :artist, name: 'The Beatles' }

    context 'when Last.fm returns bio information' do
      let(:bio_data) do
        {
          published: '03 Feb 2006, 06:05',
          summary: 'The Beatles were an English rock band.',
          content: 'Full biography content here.',
          links: []
        }
      end

      before do
        artist_finder = instance_double(Lastfm::ArtistFinder)
        allow(Lastfm::ArtistFinder).to receive(:new).and_return(artist_finder)
        allow(artist_finder).to receive(:get_info).with(artist.name).and_return({ bio: bio_data })
      end

      it 'returns status OK/200' do
        get :bio, params: { id: artist.id, format: :json }
        expect(response.status).to eq(200)
      end

      it 'returns the bio information' do
        get :bio, params: { id: artist.id, format: :json }
        expect(json[:bio][:summary]).to eq('The Beatles were an English rock band.')
      end
    end

    context 'when Last.fm does not return bio information' do
      before do
        artist_finder = instance_double(Lastfm::ArtistFinder)
        allow(Lastfm::ArtistFinder).to receive(:new).and_return(artist_finder)
        allow(artist_finder).to receive(:get_info).with(artist.name).and_return(nil)
      end

      it 'returns null bio' do
        get :bio, params: { id: artist.id, format: :json }
        expect(json[:bio]).to be_nil
      end
    end
  end
end
