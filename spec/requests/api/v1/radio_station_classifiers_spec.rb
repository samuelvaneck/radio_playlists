# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'RadioStationClassifiers API', type: :request do
  path '/api/v1/radio_station_classifiers' do
    get 'List all radio station classifiers' do
      tags 'Radio Station Classifiers'
      produces 'application/json'
      description 'Returns audio feature classifiers for radio stations, aggregated by day part. ' \
                  'Includes Spotify audio features like danceability, energy, valence, etc. ' \
                  'Response includes attribute descriptions in the meta section.'
      parameter name: :radio_station_id, in: :query, type: :integer, required: false,
                description: 'Filter by radio station ID'
      parameter name: :day_part, in: :query, type: :string, required: false,
                description: 'Filter by day part (night, breakfast, morning, lunch, afternoon, dinner, evening)'

      response '200', 'Classifiers retrieved successfully' do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string },
                       type: { type: :string },
                       attributes: {
                         type: :object,
                         properties: {
                           id: { type: :integer },
                           radio_station: { type: :object },
                           day_part: { type: :string },
                           danceability: { type: :integer },
                           danceability_average: { type: :string },
                           energy: { type: :integer },
                           energy_average: { type: :string },
                           speechiness: { type: :integer },
                           speechiness_average: { type: :string },
                           acousticness: { type: :integer },
                           acousticness_average: { type: :string },
                           instrumentalness: { type: :integer },
                           instrumentalness_average: { type: :string },
                           liveness: { type: :integer },
                           liveness_average: { type: :string },
                           valence: { type: :integer },
                           valence_average: { type: :string },
                           tempo: { type: :string },
                           counter: { type: :integer }
                         }
                       }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     attribute_descriptions: {
                       type: :object,
                       properties: {
                         danceability: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             range: { type: :string }
                           }
                         },
                         energy: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             range: { type: :string }
                           }
                         },
                         speechiness: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             range: { type: :string }
                           }
                         },
                         acousticness: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             range: { type: :string }
                           }
                         },
                         instrumentalness: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             range: { type: :string }
                           }
                         },
                         liveness: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             range: { type: :string }
                           }
                         },
                         valence: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             range: { type: :string }
                           }
                         },
                         tempo: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             range: { type: :string }
                           }
                         },
                         day_part: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string },
                             values: { type: :array, items: { type: :string } }
                           }
                         },
                         counter: {
                           type: :object,
                           properties: {
                             name: { type: :string },
                             description: { type: :string }
                           }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:radio_station) { create(:radio_station) }
        let!(:classifier) { create(:radio_station_classifier, radio_station: radio_station, day_part: 'morning') }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['data'].first['attributes']['day_part']).to eq('morning')
          expect(json['data'].first['attributes']['danceability_average']).to be_present
          expect(json['data'].first['attributes']['high_danceability_percentage']).to be_present
          expect(json['meta']['attribute_descriptions']).to be_present
          expect(json['meta']['attribute_descriptions']['danceability_average']).to include('name', 'description', 'range')
          expect(json['meta']['attribute_descriptions']['high_danceability_percentage']).to include('name', 'description', 'range')
        end
      end

      response '200', 'Classifiers filtered by radio station' do
        let!(:radio_station1) { create(:radio_station) }
        let!(:radio_station2) { create(:radio_station) }
        let!(:classifier1) { create(:radio_station_classifier, radio_station: radio_station1, day_part: 'morning') }
        let!(:classifier2) { create(:radio_station_classifier, radio_station: radio_station2, day_part: 'evening') }
        let(:radio_station_id) { radio_station1.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].length).to eq(1)
          expect(json['data'].first['attributes']['day_part']).to eq('morning')
        end
      end

      response '200', 'Classifiers filtered by day part' do
        let!(:radio_station) { create(:radio_station) }
        let!(:morning_classifier) { create(:radio_station_classifier, radio_station: radio_station, day_part: 'morning') }
        let!(:evening_classifier) { create(:radio_station_classifier, radio_station: radio_station, day_part: 'evening') }
        let(:day_part) { 'evening' }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].length).to eq(1)
          expect(json['data'].first['attributes']['day_part']).to eq('evening')
        end
      end
    end
  end

  path '/api/v1/radio_station_classifiers/descriptions' do
    get 'Get attribute descriptions for audio features' do
      tags 'Radio Station Classifiers'
      produces 'application/json'
      description 'Returns detailed descriptions for all audio feature attributes used in classifiers. ' \
                  'Useful for displaying tooltips or help text in the frontend.'

      response '200', 'Descriptions retrieved successfully' do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     danceability: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         range: { type: :string }
                       }
                     },
                     energy: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         range: { type: :string }
                       }
                     },
                     speechiness: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         range: { type: :string }
                       }
                     },
                     acousticness: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         range: { type: :string }
                       }
                     },
                     instrumentalness: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         range: { type: :string }
                       }
                     },
                     liveness: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         range: { type: :string }
                       }
                     },
                     valence: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         range: { type: :string }
                       }
                     },
                     tempo: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         range: { type: :string }
                       }
                     },
                     day_part: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string },
                         values: { type: :array, items: { type: :string } }
                       }
                     },
                     counter: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         description: { type: :string }
                       }
                     }
                   }
                 }
               }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_a(Hash)
          expect(json['data']['danceability_average']).to include('name', 'description', 'range')
          expect(json['data']['high_danceability_percentage']).to include('name', 'description', 'range')
          expect(json['data']['energy_average']).to include('name', 'description', 'range')
          expect(json['data']['valence_average']).to include('name', 'description', 'range')
          expect(json['data']['tempo']).to include('name', 'description', 'range')
          expect(json['data']['day_part']).to include('name', 'description', 'values')
        end
      end
    end
  end
end
