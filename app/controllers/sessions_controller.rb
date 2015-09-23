class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, :set_organization, :authorize_organization_access

  def new
    redirect_to '/auth/github'
  end

  def create
    auth_hash = request.env['omniauth.auth']
    user      = User.find_by_auth_hash(auth_hash) || User.new

    user.assign_from_auth_hash(auth_hash)

    session[:user_id] = user.id

    url = session[:pre_login_destination] || organizations_path
    redirect_to url
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  def failure
    redirect_to root_path, alert: params[:message]
  end
end
