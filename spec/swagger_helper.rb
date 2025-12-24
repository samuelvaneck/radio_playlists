# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Radio Playlists API',
        version: 'v1',
        description: 'API for tracking songs played on Dutch radio stations with Spotify and YouTube integration'
      },
      paths: {},
      servers: [
        {
          url: 'https://api.radioplaylists.nl',
          description: 'Production server'
        },
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        }
      ],
      components: {
        schemas: {
          Song: {
            type: :object,
            properties: {
              id: { type: :string },
              type: { type: :string, example: 'song' },
              attributes: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  title: { type: :string },
                  search_text: { type: :string, nullable: true },
                  spotify_song_url: { type: :string, nullable: true },
                  spotify_artwork_url: { type: :string, nullable: true },
                  spotify_preview_url: { type: :string, nullable: true },
                  id_on_youtube: { type: :string, nullable: true },
                  release_date: { type: :string, format: :date, nullable: true },
                  release_date_precision: { type: :string, nullable: true },
                  artists: { type: :array, items: { '$ref' => '#/components/schemas/ArtistCompact' } },
                  counter: { type: :integer, nullable: true },
                  position: { type: :integer, nullable: true }
                }
              }
            }
          },
          Artist: {
            type: :object,
            properties: {
              id: { type: :string },
              type: { type: :string, example: 'artist' },
              attributes: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string },
                  spotify_artist_url: { type: :string, nullable: true },
                  spotify_artwork_url: { type: :string, nullable: true },
                  instagram_url: { type: :string, nullable: true },
                  website_url: { type: :string, nullable: true },
                  counter: { type: :integer, nullable: true }
                }
              }
            }
          },
          ArtistCompact: {
            type: :object,
            properties: {
              data: {
                type: :object,
                properties: {
                  id: { type: :string },
                  type: { type: :string },
                  attributes: {
                    type: :object,
                    properties: {
                      id: { type: :integer },
                      name: { type: :string }
                    }
                  }
                }
              }
            }
          },
          AirPlay: {
            type: :object,
            properties: {
              id: { type: :string },
              type: { type: :string, example: 'air_play' },
              attributes: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  broadcasted_at: { type: :string, format: 'date-time' },
                  created_at: { type: :string, format: 'date-time' },
                  song: { '$ref' => '#/components/schemas/Song' },
                  radio_station: { '$ref' => '#/components/schemas/RadioStation' },
                  artists: { type: :array, items: { '$ref' => '#/components/schemas/ArtistCompact' } }
                }
              }
            }
          },
          RadioStation: {
            type: :object,
            properties: {
              id: { type: :string },
              type: { type: :string, example: 'radio_station' },
              attributes: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string },
                  slug: { type: :string, nullable: true },
                  stream_url: { type: :string, nullable: true },
                  country_code: { type: :string }
                }
              }
            }
          },
          Bio: {
            type: :object,
            properties: {
              bio: {
                type: :object,
                nullable: true,
                properties: {
                  summary: { type: :string, nullable: true },
                  content: { type: :string, nullable: true },
                  description: { type: :string, nullable: true },
                  url: { type: :string, nullable: true },
                  wikibase_item: { type: :string, nullable: true },
                  thumbnail: {
                    type: :object,
                    nullable: true,
                    properties: {
                      source: { type: :string },
                      width: { type: :integer },
                      height: { type: :integer }
                    }
                  },
                  original_image: {
                    type: :object,
                    nullable: true,
                    properties: {
                      source: { type: :string },
                      width: { type: :integer },
                      height: { type: :integer }
                    }
                  },
                  general_info: {
                    type: :object,
                    nullable: true,
                    properties: {
                      date_of_birth: { type: :string, nullable: true },
                      place_of_birth: { type: :string, nullable: true },
                      nationality: { type: :array, items: { type: :string }, nullable: true },
                      genres: { type: :array, items: { type: :string }, nullable: true },
                      occupations: { type: :array, items: { type: :string }, nullable: true },
                      official_website: { type: :string, nullable: true },
                      active_years: {
                        type: :object,
                        nullable: true,
                        properties: {
                          start: { type: :string, nullable: true },
                          end: { type: :string, nullable: true }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          ChartPosition: {
            type: :object,
            properties: {
              date: { type: :string, format: :date },
              position: { type: :integer },
              counts: { type: :integer }
            }
          },
          TimeAnalytics: {
            type: :object,
            properties: {
              peak_play_times: {
                type: :object,
                properties: {
                  peak_hour: { type: :integer, nullable: true },
                  peak_day: { type: :integer, nullable: true },
                  peak_day_name: { type: :string, nullable: true },
                  hourly_distribution: { type: :object },
                  daily_distribution: { type: :object }
                }
              },
              play_frequency_trend: {
                type: :object,
                nullable: true,
                properties: {
                  trend: { type: :string },
                  trend_percentage: { type: :number },
                  weekly_counts: { type: :array, items: { type: :integer } },
                  first_period_avg: { type: :number },
                  second_period_avg: { type: :number }
                }
              },
              lifecycle_stats: {
                type: :object,
                nullable: true,
                properties: {
                  first_play: { type: :string, format: 'date-time' },
                  last_play: { type: :string, format: 'date-time' },
                  total_plays: { type: :integer },
                  days_active: { type: :integer }
                }
              }
            }
          },
          PaginatedResponse: {
            type: :object,
            properties: {
              data: { type: :array, items: { type: :object } },
              total_entries: { type: :integer },
              total_pages: { type: :integer },
              current_page: { type: :integer }
            }
          },
          Error: {
            type: :object,
            properties: {
              errors: { type: :array, items: { type: :string } },
              status: { type: :string }
            }
          }
        },
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
