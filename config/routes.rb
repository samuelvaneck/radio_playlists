Rails.application.routes.draw do

  resources :radiostations do
    resources :playlists do
      resources :songs
    end
  end

end
