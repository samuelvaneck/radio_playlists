Rails.application.routes.draw do

  resources :playlists
  resources :radio538playlists

  root 'playlists#index'

end
