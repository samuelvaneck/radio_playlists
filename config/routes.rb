Rails.application.routes.draw do

  resources :generalplaylists do
    collection {
      get :today_played_songs
      get :top_songs
      get :top_artists
      get :autocomplete
      get :song_details
    }
  end

  root 'generalplaylists#index'

end
