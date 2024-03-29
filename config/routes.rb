# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  resources :playlists, only: %i[index show]
  resources :artists, only: %i[index show] do
    get :graph_data, on: :member
  end
  resources :songs, only: %i[index show] do
    get :graph_data, on: :member
  end
  resources :radio_stations, only: %i[index show] do
    get :status, on: :member
  end
  resources :charts, only: %i[show]

  root 'home#index'

  mount Sidekiq::Web => '/sidekiq'
  mount HealthBit.rack => '/health'
end
