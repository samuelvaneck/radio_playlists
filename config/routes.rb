Rails.application.routes.draw do

  resources :playlists do
    collection { get :autocomplete }
  end

  resources :radio538playlists do
    collection { get :autocomplete }
  end

  root 'playlists#index'

end
