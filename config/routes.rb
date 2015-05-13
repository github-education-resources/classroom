Rails.application.routes.draw do
  resources :users, only: [:show]

  root to: 'pages#home'

  get '/login',  to: 'sessions#new',     as: 'login'
  get '/logout', to: 'sessions#destroy', as: 'logout'

  get   '/auth/failure',            to: 'sessions#failure'
  match '/auth/:provider/callback', to: 'sessions#create',  via: [:get, :post]
end
