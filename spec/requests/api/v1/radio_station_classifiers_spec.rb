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
        example 'application/json', :example, {
          data: [
            {
              id: '1',
              type: 'radio_station_classifier',
              attributes: {
                id: 1,
                radio_station: { id: 1, name: 'Radio 538' },
                day_part: 'morning',
                danceability_average: '0.65',
                high_danceability_percentage: 0.72,
                energy_average: '0.72',
                high_energy_percentage: 0.68,
                speechiness_average: '0.08',
                high_speechiness_percentage: 0.15,
                acousticness_average: '0.25',
                high_acousticness_percentage: 0.30,
                instrumentalness_average: '0.02',
                high_instrumentalness_percentage: 0.05,
                liveness_average: '0.12',
                high_liveness_percentage: 0.18,
                valence_average: '0.58',
                high_valence_percentage: 0.62,
                tempo: '118.5',
                counter: 450
              }
            }
          ],
          meta: {
            attribute_descriptions: {
              danceability_average: {
                name: 'Danceability Average',
                description: 'Average danceability score for tracks played during this time period.',
                range: '0.0 to 1.0'
              },
              high_danceability_percentage: {
                name: 'High Danceability Percentage',
                description: 'Percentage of tracks with danceability above the threshold.',
                range: '0.0 to 1.0'
              },
              energy_average: {
                name: 'Energy Average',
                description: 'Average energy score for tracks played during this time period.',
                range: '0.0 to 1.0'
              },
              day_part: {
                name: 'Day Part',
                description: 'Time segment of the day.',
                values: %w[night breakfast morning lunch afternoon dinner evening]
              },
              counter: {
                name: 'Counter',
                description: 'Number of tracks analyzed for this classifier.'
              }
            }
          }
        }

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
        let!(:song) { create(:song) }
        let!(:music_profile) { create(:music_profile, song: song) }
        # Use a morning time (10:30) that's guaranteed to be within the last 24 hours
        let(:morning_time) do
          time = Time.current.change(hour: 10, min: 30)
          time > Time.current ? time - 1.day : time
        end
        let!(:air_play) do
          create(:air_play, song: song, radio_station: radio_station, broadcasted_at: morning_time)
        end

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
        example 'application/json', :filtered_by_station, {
          data: [
            {
              id: '1',
              type: 'radio_station_classifier',
              attributes: {
                id: 1,
                radio_station: { id: 1, name: 'Radio 538' },
                day_part: 'morning',
                danceability_average: '0.65',
                energy_average: '0.72',
                counter: 450
              }
            }
          ],
          meta: { attribute_descriptions: {} }
        }

        let!(:radio_station1) { create(:radio_station) }
        let!(:radio_station2) { create(:radio_station) }
        let!(:song1) { create(:song) }
        let!(:song2) { create(:song) }
        let!(:music_profile1) { create(:music_profile, song: song1) }
        let!(:music_profile2) { create(:music_profile, song: song2) }
        # Use times that are guaranteed to be within the last 24 hours
        let(:morning_time) do
          time = Time.current.change(hour: 10, min: 30)
          time > Time.current ? time - 1.day : time
        end
        let(:evening_time) do
          time = Time.current.change(hour: 21, min: 0)
          time > Time.current ? time - 1.day : time
        end
        let!(:air_play1) do
          create(:air_play, song: song1, radio_station: radio_station1, broadcasted_at: morning_time)
        end
        let!(:air_play2) do
          create(:air_play, song: song2, radio_station: radio_station2, broadcasted_at: evening_time)
        end
        let(:radio_station_id) { radio_station1.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].length).to eq(1)
          expect(json['data'].first['attributes']['day_part']).to eq('morning')
        end
      end

      response '200', 'Classifiers filtered by day part' do
        example 'application/json', :filtered_by_day_part, {
          data: [
            {
              id: '1',
              type: 'radio_station_classifier',
              attributes: {
                id: 1,
                radio_station: { id: 1, name: 'Radio 538' },
                day_part: 'evening',
                danceability_average: '0.75',
                energy_average: '0.80',
                counter: 320
              }
            }
          ],
          meta: { attribute_descriptions: {} }
        }

        let!(:radio_station) { create(:radio_station) }
        let!(:song1) { create(:song) }
        let!(:song2) { create(:song) }
        let!(:music_profile1) { create(:music_profile, song: song1) }
        let!(:music_profile2) { create(:music_profile, song: song2) }
        # Use times that are guaranteed to be within the last 24 hours
        let(:morning_time) do
          time = Time.current.change(hour: 10, min: 30)
          time > Time.current ? time - 1.day : time
        end
        let(:evening_time) do
          time = Time.current.change(hour: 21, min: 0)
          time > Time.current ? time - 1.day : time
        end
        let!(:morning_air_play) do
          create(:air_play, song: song1, radio_station: radio_station, broadcasted_at: morning_time)
        end
        let!(:evening_air_play) do
          create(:air_play, song: song2, radio_station: radio_station, broadcasted_at: evening_time)
        end
        let(:radio_station_id) { radio_station.id }
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
        example 'application/json', :example, {
          data: {
            danceability_average: {
              name: 'Danceability Average',
              description: 'Average danceability score for tracks played during this time period. Higher values indicate more danceable tracks.',
              range: '0.0 to 1.0'
            },
            high_danceability_percentage: {
              name: 'High Danceability Percentage',
              description: 'Percentage of tracks with danceability above 0.5.',
              range: '0.0 to 1.0'
            },
            energy_average: {
              name: 'Energy Average',
              description: 'Average energy score for tracks. Higher values indicate more intense, fast, loud tracks.',
              range: '0.0 to 1.0'
            },
            valence_average: {
              name: 'Valence Average',
              description: 'Average musical positiveness. Higher values indicate happier, more cheerful tracks.',
              range: '0.0 to 1.0'
            },
            tempo: {
              name: 'Tempo',
              description: 'Average tempo of tracks in beats per minute (BPM).',
              range: '0 to 250 BPM'
            },
            day_part: {
              name: 'Day Part',
              description: 'Time segment of the day when tracks were played.',
              values: %w[night breakfast morning lunch afternoon dinner evening]
            },
            counter: {
              name: 'Counter',
              description: 'Number of tracks analyzed for this classifier.'
            }
          }
        }

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
