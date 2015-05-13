class UsersController < ApplicationController
  before_action :ensure_logged_in, :set_user

  def show
    @orgs = @user.organizations
  end

  private

  def set_user
    @user = User.find(session[:user_id])
  end
end
