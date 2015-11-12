module Stafftools
  class UsersController < StafftoolsController
    skip_before_action :authorize_access, only: [:stop_impersonating]

    before_action :set_user,  only: [:impersonate]
    before_action :set_users, only: [:index, :search]

    def index
    end

    def search
      respond_to do |format|
        format.html { render partial: 'stafftools/users/users', locals: { users: @users } }
      end
    end

    def impersonate
      session[:impersonated_user_id] = @user.id
      redirect_to root_path
    end

    def stop_impersonating
      not_found unless true_user.try(:staff?)

      session.delete(:impersonated_user_id)
      redirect_to stafftools_root_path
    end

    private

    def set_user
      @user = User.find_by(id: params[:id])
    end

    def set_users
      match_phrase_prefix = { match_phrase_prefix: { login: params[:query] } }
      wildcard            = { wildcard:            { login: '*' }            }

      user_query = params[:query].present? ? match_phrase_prefix : wildcard
      @users = UsersIndex::User.query(user_query).page(params[:page]).per(20)
    end
  end
end
