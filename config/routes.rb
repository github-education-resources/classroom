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

    root to: 'resources#index'
    get '/resource_search', to: 'resources#search'

    resources :users, except: [:index, :new, :create] do
      member do
        post :impersonate
        delete :stop_impersonating
      end
    end

    resources :organizations, except: [:index, :new, :create]

    resources :repo_accesses, except: [:index, :new, :create]

    resources :assignment_invitations, except: [:index, :new, :create]
    resources :assignment_repos,       except: [:index, :new, :create]
    resources :assignments,            except: [:index, :new, :create]

    resources :group_assignment_invitations, path: 'group-assignment-invitations', except: [:index, :new, :create]
    resources :group_assignment_repos,       path: 'group-assignment-repos',       except: [:index, :new, :create]
    resources :group_assignments,            path: 'group-assignments',            except: [:index, :new, :create]

    resources :groupings, except: [:index, :new, :create]
    resources :groups,    except: [:index, :new, :create]
  end
end
