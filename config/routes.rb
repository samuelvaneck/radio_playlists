# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  resources :generalplaylists, only: %i[index show]
  resources :artists, only: %i[index show]
  resources :songs, only: %i[index show]
  resources :radiostations, only: %i[index show]

  root 'generalplaylists#index'

  mount Sidekiq::Web => '/sidekiq'
end
