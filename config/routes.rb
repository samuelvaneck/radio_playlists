Rails.application.routes.draw do

  resources :playlists
  resources :radio_538_playlists

  root 'playlists#index'

end
