module Stafftools
  class UsersController < StafftoolsController
    before_action :set_user, only: [:impersonate]
    skip_before_action :authorize_access, only: [:stop_impersonating]

    def impersonate
      if @user
        session[:impersonated_user_id] = @user.id
        redirect_to root_path
      else
        flash[:error] = 'This user does not exist on Classroom for GitHub'
        redirect_to :back
      end
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
  end
end
