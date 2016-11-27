Rails.application.routes.draw do

  resources :playlists do
    collection {
      get :autocomplete
      get :sort_today
      get :sort_week
      get :sort_month
      get :sort_year
      get :sort_total
      get :sort_created
      get :sort_updated
    }
  end

  resources :radio2playlists do
    collection {
      get :autocomplete
      get :sort_today
      get :sort_week
      get :sort_month
      get :sort_year
      get :sort_total
      get :sort_created
      get :sort_updated
    }
  end

  resources :radio538playlists do
    collection {
      get :autocomplete
      get :sort_today
      get :sort_week
      get :sort_month
      get :sort_year
      get :sort_total
      get :sort_created
      get :sort_updated
    }
  end

  resources :sublimefmplaylists do
    collection {
      get :autocomplete
      get :sort_today
      get :sort_week
      get :sort_month
      get :sort_year
      get :sort_total
      get :sort_created
      get :sort_updated
    }
  end

  resources :grootnieuwsplaylists do
    collection {
      get :autocomplete
      get :sort_today
      get :sort_week
      get :sort_month
      get :sort_year
      get :sort_total
      get :sort_created
      get :sort_updated
    }
  end

  resources :generalplaylists

  root 'generalplaylists#index'

end
