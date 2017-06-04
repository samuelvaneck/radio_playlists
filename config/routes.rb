Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :generalplaylists
  get '/auth/spotify/callback', to: 'users#spotify'
  get '/auth/failure', to: 'generalplaylists#index'

  root 'generalplaylists#index'

end
