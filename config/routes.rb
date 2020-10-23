# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  resources :generalplaylists, only: %i[index show]
  resources :artists, only: %i[index show]
  resources :songs, only: %i[index show]
  resources :radiostations, only: %i[index show]

  get '/users/auth/spotify/callback', to: 'users/omniauth_callbacks#spotify'
  get '/users/auth/failure', to: 'users/omniauth_callbacks#failure'

  root 'generalplaylists#index'

  mount Sidekiq::Web => '/sidekiq'
end
