Rails.application.routes.draw do
  root to: 'pages#home'

  get '/login',  to: 'sessions#new',     as: 'login'
  get '/logout', to: 'sessions#destroy', as: 'logout'

  match '/auth/:provider/callback', to: 'sessions#create',  via: [:get, :post]
  match '/auth/failure',            to: 'sessions#failure', via: [:get, :post]

  get 'dashboard', to: 'users#show'

  resources :invitations, only: [:show]

  resources :organizations do
    member do
      get 'setup'
      patch 'add_students_team'
    end

    resources :assignments
  end
end
