# frozen_string_literal: true

require "sidekiq/web"
require "staff_constraint"
require "googleauth"

Rails.application.routes.draw do
  mount Peek::Railtie => "/peek"
  mount ActionCable.server => "/cable"

  root to: "pages#home"

  get "/assistant", to: "pages#assistant"
  get "/help/(:article_name)", to: "pages#help", as: "help"
  get "/home", to: "pages#home"

  get  "/login",  to: "sessions#new",     as: "login"
  post "/logout", to: "sessions#destroy", as: "logout"

  get  "/login/oauth/authorize", to: "oauth#authorize"
  post  "/login/oauth/access_token", to: "oauth#access_token"

  match "/auth/lti/setup",          to: "sessions#lti_setup",     via: %i[get post]
  match "/auth/lti/launch",         to: "sessions#lti_launch",    via: %i[get post]
  match "/auth/:provider/callback", to: "sessions#create",        via: %i[get post]
  match "/auth/failure",            to: "sessions#failure",       via: %i[get post]

  match "/google_classroom/oauth2_callback", to: Google::Auth::WebUserAuthorizer::CallbackApp, via: :all
  get "/google_classroom/list", to: "google_classroom#index"

  get "/a/:short_key", to: "short_url#assignment_invitation",       as: "assignment_invitation_short"
  get "/g/:short_key", to: "short_url#group_assignment_invitation", as: "group_assignment_invitation_short"

  get "/autocomplete/github_repos", to: "autocomplete#github_repos"

  get "/boom", to: "site#boom_town"
  get "/boom/sidekiq", to: "site#boom_sidekiq"

  scope "github", as: "github" do
    constraints user_agent: %r{\AGitHub-Hookshot/\w+\z}, format: "json" do
      post :hooks, to: "hooks#receive"
    end
  end

  resources :assignment_invitations, path: "assignment-invitations", only: [:show] do
    member do
      patch :accept
      get   :setup
      post  :create_repo
      get   :progress
      get   :success
      patch :join_roster
    end
  end

  resources :group_assignment_invitations, path: "group-assignment-invitations", only: [:show] do
    member do
      get   :accept
      patch :accept_assignment
      patch :accept_invitation
      get   :setup
      post  :create_repo
      get   :progress
      get   :successful_invitation, path: :success
      patch :join_roster
    end
  end

  scope path_names: { edit: "settings" } do
    resources :organizations, path: "classrooms" do
      collection do
        get :search
      end

      member do
        get   :invite
        get   :new_assignment, path: "new-assignment"
        get   :setup
        patch :setup_organization
        get   "settings/invitations", to: "organizations#invitation"
        get   "settings/teams",       to: "organizations#show_groupings"
        delete "users/:user_id",      to: "organizations#remove_user", as: "remove_user"

        resource :roster, only: %i[show new create], controller: "orgs/rosters" do
          patch :link
          patch :unlink
          patch :delete_entry
          patch :add_students
          patch :remove_organization
          patch :import_from_lms
          patch :import_from_google_classroom
          patch :sync_google_classroom
          patch :unlink_google_classroom
          get   :select_google_classroom
          get   :search_google_classroom
        end

        resource :lti_configuration, controller: "orgs/lti_configurations" do
          get :autoconfigure
        end
      end

      resources :groupings, only: %i[show edit update] do
        resources :groups, only: [:show] do
          member do
            patch "/memberships/:user_id", to: "groups#add_membership", as: "add_membership"
            delete "/memberships/:user_id", to: "groups#remove_membership", as: "remove_membership"
          end
        end
      end

      resources :assignments do
        resources :assignment_repos, only: [:show], controller: "orgs/assignment_repos"
        get "/roster_entries/:roster_entry_id", to: "orgs/roster_entries#show", as: "roster_entry"
        get :assistant, on: :member
      end

      resources :group_assignments, path: "group-assignments" do
        resources :group_assignment_repos, only: [:show], controller: "orgs/group_assignment_repos"
        get "/roster_entries/:roster_entry_id", to: "orgs/roster_entries#show", as: "roster_entry"
        get :assistant, on: :member
      end
    end
  end

  resources :videos, only: [:index]

  namespace :stafftools do
    constraints StaffConstraint.new do
      mount Sidekiq::Web => "/sidekiq"
      mount Flipper::UI.app(GitHubClassroom.flipper) => "/flipper", as: "flipper"
    end

    root "resources#index", as: :root
    get "/resource_search", to: "resources#search"

    resources :users, only: [:show] do
      member do
        post :impersonate
        delete :stop_impersonating
      end
    end

    resources :organizations, path: "classrooms", only: [:show] do
      member do
        delete "/users/:user_id", to: "organizations#remove_user", as: "remove_user"
        post :ensure_webhook_is_active
      end
    end

    resources :repo_accesses, only: [:show]

    resources :assignment_invitations, only: [:show]
    resources :assignment_repos,       only: %i[show destroy]
    resources :assignments,            only: [:show]

    resources :deadlines, only: [:show]

    resources :group_assignment_invitations, path: "group-assignment-invitations", only: [:show]
    resources :group_assignment_repos,       path: "group-assignment-repos",       only: %i[show destroy]
    resources :group_assignments,            path: "group-assignments",            only: [:show]

    resources :groupings, only: [:show]
    resources :groups,    only: [:show]
  end

  namespace :api, defaults: { format: :json } do
    scope :internal do
      resources :organizations, path: "classrooms", only: [:index] do
        resources :assignments, only: %i[index show] do
          resources :assignment_repos, only: [:index] do
            get "/clone_url", to: "assignment_repos#clone_url"
          end
        end
        resources :group_assignments, path: "group-assignments", only: %i[index show] do
          resources :group_assignment_repos, path: "group-assignment-repos", only: [:index] do
            get "/clone_url", to: "group_assignment_repos#clone_url"
          end
        end
      end
      get "/user", to: "users#authenticated_user"
    end
  end
end
