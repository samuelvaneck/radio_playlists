# frozen_string_literal: true

require 'sidekiq_unique_jobs/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  devise_for :admins
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      devise_for :admins, controllers: { sessions: 'api/v1/admins/auth_token' }
      get 'admins/current', to: 'admins/current_admin#show'
      get 'admins/songs', to: 'admins/songs#index'
      patch 'admins/songs/:id', to: 'admins/songs#update'
      get 'admins/artists', to: 'admins/artists#index'
      patch 'admins/artists/:id', to: 'admins/artists#update'

      resources :air_plays, only: %i[index]
      # Redirect old playlists routes to air_plays
      get '/playlists', to: redirect('/api/v1/air_plays')
      resources :artists, only: %i[index show] do
        get :graph_data, on: :member
        get :songs, on: :member
        get :chart_positions, on: :member
        get :time_analytics, on: :member
        get :air_plays, on: :member
        get :bio, on: :member
      end
      resources :songs, only: %i[index show] do
        get :graph_data, on: :member
        get :chart_positions, on: :member
        get :time_analytics, on: :member
        get :air_plays, on: :member
        get :info, on: :member
        get :music_profile, on: :member
      end
      resources :radio_stations, only: %i[index show] do
        get :data, on: :member
        get :classifiers, on: :member
        get :status, on: :member
        get :stream_proxy, on: :member
        get :timeline, on: :member
        get :last_played_songs, on: :collection
        get :new_played_songs, on: :collection
      end
      resources :radio_station_classifiers, only: %i[index] do
        get :descriptions, on: :collection
      end
      resources :song_import_logs, only: %i[index]
    end
  end

  mount Sidekiq::Web => '/sidekiq'
  mount HealthBit.rack => '/health'
end
