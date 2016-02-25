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
      get   :unsuccessful_invitation
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

    root to: 'resources#index'
    get '/resource_search', to: 'resources#search'

    resources :users, only: [:show] do
      member do
        post :impersonate
        delete :stop_impersonating
      end
    end

    resources :organizations, path: 'classrooms', only: [:show]

    resources :repo_accesses, only: [:show]

    resources :assignment_invitations, only: [:show]
    resources :assignment_repos,       only: [:show]
    resources :assignments,            only: [:show]

    resources :group_assignment_invitations, path: 'group-assignment-invitations', only: [:show]
    resources :group_assignment_repos,       path: 'group-assignment-repos',       only: [:show]
    resources :group_assignments,            path: 'group-assignments',            only: [:show]

    resources :groupings, only: [:show]
    resources :groups,    only: [:show]
  end
end
