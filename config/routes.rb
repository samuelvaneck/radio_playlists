Rails.application.routes.draw do

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  resources :generalplaylists
  get '/users/auth/spotify/callback', to: 'users/omniauth_callbacks#spotify'
  get '/users/auth/failure', to: 'users/omniauth_callbacks#failure'

  root 'generalplaylists#index'

end
