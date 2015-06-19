Rails.application.routes.draw do
  root to: 'pages#home'

  get '/login',  to: 'sessions#new',     as: 'login'
  get '/logout', to: 'sessions#destroy', as: 'logout'

  match '/auth/:provider/callback', to: 'sessions#create',  via: [:get, :post]
  match '/auth/failure',            to: 'sessions#failure', via: [:get, :post]

  get 'dashboard', to: 'users#show'

  resources :assignment_invitations, only: [:show] do
    member do
      get 'accept_invitation'
    end
  end

  resources :group_assignment_invitations, only: [:show] do
    member do
      get 'accept_invitation'
    end
  end

  resources :organizations do
    member do
      get 'new_assignment'
    end

    resources :assignments,       only: [:show, :new, :create]
    resources :group_assignments, only: [:show, :new, :create]
  end
end
