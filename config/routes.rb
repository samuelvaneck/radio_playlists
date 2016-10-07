Rails.application.routes.draw do

  resources :playlists do
    collection { get :autocomplete }
  end

  resources :radio2playlists do
    collection { get :autocomplete }
  end

  resources :radio538playlists do
    collection { get :autocomplete }
  end

  resources :sublimefmplaylists do
    collection { get :autocomplete }
  end

  root 'playlists#index'

end
