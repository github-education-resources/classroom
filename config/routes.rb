Rails.application.routes.draw do
  root to: 'pages#home'

  get '/login',  to: 'sessions#new',     as: 'login'
  get '/logout', to: 'sessions#destroy', as: 'logout'

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  post  '/auth/failure',            to: 'sessions#failure'

  get 'dashboard', to: 'users#show'

  resources :organizations, except: [:edit, :update, :destroy], path: 'classroom'
end
