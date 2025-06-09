# frozen_string_literal: true

require 'sidekiq_unique_jobs/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  devise_for :admins, skip: [:registrations, :passwords, :confirmations, :unlocks]
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      devise_for :admins, controllers: { sessions: 'api/v1/admins/auth_token' }
      post 'admins/refresh_token', to: 'admins/refresh_tokens#create'
      get 'admins/current', to: 'admins/current_admin#show'
      get 'admins/songs', to: 'admins/songs#index'
      patch 'admins/songs/:id', to: 'admins/songs#update'

      resources :air_plays, only: %i[index]
      # Redirect old playlists routes to air_plays
      get '/playlists', to: redirect('/api/v1/air_plays')
      resources :artists, only: %i[index show] do
        get :graph_data, on: :member
        get :songs, on: :member
        get :chart_positions, on: :member
      end
      resources :songs, only: %i[index show] do
        get :graph_data, on: :member
        get :chart_positions, on: :member
      end
      resources :radio_stations, only: %i[index show] do
        get :data, on: :member
        get :classifiers, on: :member
        get :status, on: :member
        get :last_played_songs, on: :collection
        get :new_played_songs, on: :collection
      end
    end
  end

  mount Sidekiq::Web => '/sidekiq'
  mount HealthBit.rack => '/health'
end
