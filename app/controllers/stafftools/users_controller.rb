# frozen_string_literal: true

module Stafftools
  class UsersController < StafftoolsController
    skip_before_action :authorize_access, only: [:stop_impersonating]

    before_action :set_user, except: [:stop_impersonating]

    def show; end

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
      @user = User.find_by!(id: params[:id])
    end
  end
end
