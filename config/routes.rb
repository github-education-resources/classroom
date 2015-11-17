require 'sidekiq/web'
require 'staff_constraint'

Rails.application.routes.draw do
  mount Peek::Railtie => '/peek'

  root to: 'pages#home'

  get  '/login',  to: 'sessions#new',     as: 'login'
  post '/logout', to: 'sessions#destroy', as: 'logout'

  match '/auth/:provider/callback', to: 'sessions#create',  via: [:get, :post]
  match '/auth/failure',            to: 'sessions#failure', via: [:get, :post]

  resources :assignment_invitations, path: 'assignment-invitations', only: [:show] do
    member do
      patch :accept_invitation
      get   :successful_invitation, path: :success
    end
  end

  resources :group_assignment_invitations, path: 'group-assignment-invitations', only: [:show] do
    member do
      get   :accept
      patch :accept_assignment
      patch :accept_invitation
      get   :successful_invitation, path: :success
    end
  end

  scope path_names: { edit: 'settings' } do
    resources :organizations, path: 'classrooms' do
      member do
        get   :invite
        get   :new_assignment, path: 'new-assignment'
        get   :setup
        patch :setup_organization
      end

      resources :assignments
      resources :group_assignments, path: 'group-assignments'
    end
  end

  namespace :stafftools do
    mount Sidekiq::Web  => '/sidekiq', constraints: StaffConstraint.new

    root action: :resources
    get :search

    resources :users, only: [:show] do
      member do
        patch :impersonate
        delete :stop_impersonating
      end
    end
  end
end
