# frozen_string_literal: true

require 'sidekiq_unique_jobs/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  devise_for :admins
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      devise_for :admins, controllers: { sessions: 'api/v1/admins/auth_token' }
      get 'admins/current', to: 'admins/current_admin#show'

      resources :playlists, only: %i[index show]
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
