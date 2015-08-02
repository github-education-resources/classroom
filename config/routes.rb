require 'organization_authorized_constraint'
require 'staff_constraint'

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Peek::Railtie => '/peek',    constraints: StaffConstraint.new
  mount Sidekiq::Web  => '/sidekiq', constraints: StaffConstraint.new

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
      patch 'accept_invitation'
    end
  end

  resources :organizations, constraints: OrganizationAuthorizedConstraint.new do
    member do
      get   'invite'
      get   'new_assignment'
      patch 'invite_users'
    end

    resources :assignments,       only: [:show, :new, :create]
    resources :group_assignments, only: [:show, :new, :create]
  end
end
