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

    def enable_feature_previewing
      if @user.update_attributes(feature_previewer: true)
        flash[:success] = "#{@user.github_user.login} can now see select preview features"
      else
        flash[:error] = "We weren't able to enable seeing preview features for #{@user.github_user.login}"
      end

      redirect_to stafftools_user_path(@user)
    end

    def disable_feature_previewing
      if @user.update_attributes(feature_previewer: false)
        flash[:success] = "#{@user.github_user.login} can no longer see select preview features"
      else
        flash[:error] = "We weren't able to remove #{@user.github_user.login} from seeing preview features"
      end

      redirect_to stafftools_user_path(@user)
    end

    private

    def set_user
      @user = User.find_by!(id: params[:id])
    end
  end
end
