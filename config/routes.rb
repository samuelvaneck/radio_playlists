# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
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
