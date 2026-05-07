# frozen_string_literal: true

require 'sidekiq_unique_jobs/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  get 'sitemap.xml', to: 'sitemap#show', defaults: { format: :xml }

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  devise_for :admins
  namespace :api, defaults: { format: :json } do # rubocop:disable Metrics/BlockLength
    namespace :v1 do # rubocop:disable Metrics/BlockLength
      devise_for :admins, controllers: { sessions: 'api/v1/admins/auth_token' }
      get 'admins/current', to: 'admins/current_admin#show'
      get 'admins/songs', to: 'admins/songs#index'
      patch 'admins/songs/:id', to: 'admins/songs#update'
      get 'admins/artists', to: 'admins/artists#index'
      patch 'admins/artists/:id', to: 'admins/artists#update'
      get 'admins/radio_stations', to: 'admins/radio_stations#index'

      resources :air_plays, only: %i[index]
      # Redirect old playlists routes to air_plays
      get '/playlists', to: redirect('/api/v1/air_plays')
      resources :artists, only: %i[index show] do
        get :autocomplete, on: :collection
        get :search, on: :collection
        get :natural_language_search, on: :collection
        get :search_suggestions, on: :collection
        get :graph_data, on: :member
        get :songs, on: :member
        get :chart_positions, on: :member
        get :time_analytics, on: :member
        get :air_plays, on: :member
        get :bio, on: :member
        get :similar_artists, on: :member
        get :widget, on: :member
      end
      resources :songs, only: %i[index show] do
        get :autocomplete, on: :collection
        get :search, on: :collection
        get :natural_language_search, on: :collection
        get :search_suggestions, on: :collection
        get :graph_data, on: :member
        get :chart_positions, on: :member
        get :time_analytics, on: :member
        get :air_plays, on: :member
        get :info, on: :member
        get :lyrics, on: :member
        get 'lyrics/text', on: :member, action: :lyrics_text, as: :lyrics_text
        get :music_profile, on: :member
        get :widget, on: :member
      end
      resources :radio_stations, only: %i[index show] do
        get :data, on: :member
        get :classifiers, on: :member
        get :status, on: :member
        get :stream_proxy, on: :member
        get :widget, on: :member
        get :sound_profile, on: :member
        get :sentiment_trend, on: :member
        get :bar_chart_race, on: :member
        get :diversity_metrics, on: :member
        get :exposure_saturation, on: :member
        get :last_played_songs, on: :collection
        get :new_played_songs, on: :collection
        get :release_date_graph, on: :collection
        get :seasonal_audio_trends, on: :collection
      end
      resources :radio_station_classifiers, only: %i[index] do
        get :descriptions, on: :collection
      end
      resources :charts, only: %i[index] do
        get :search, on: :collection
        get :autocomplete, on: :collection
      end
      post 'client_tokens', to: 'client_tokens#create'
      get 'admins/song_import_logs', to: 'song_import_logs#index'
    end
  end

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch('SIDEKIQ_USERNAME', 'admin')) &
      ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('SIDEKIQ_PASSWORD', ''))
  end
  mount Sidekiq::Web => '/sidekiq'
  mount HealthBit.rack => '/health'
end
