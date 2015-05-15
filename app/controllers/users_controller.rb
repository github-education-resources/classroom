class UsersController < ApplicationController
  before_action :redirect_to_root, unless: :logged_in?
  before_action :set_user

  def show
    @organizations = @user.organizations
  end

  private

  def set_user
    @user = User.find(session[:user_id])
  end
end
