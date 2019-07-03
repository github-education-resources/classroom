# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!,         except: [:lti_callback]
  skip_before_action :verify_authenticity_token,  only: [:lti_launch]
  before_action      :verify_lti_launch_enabled,  only: %i[lti_launch lti_callback]

  def new
    scopes = session[:required_scopes] || default_required_scopes
    scope_param = { scope: scopes }.to_param
    redirect_to "/auth/github?#{scope_param}"
  end

  def default_required_scopes
    GitHubClassroom::Scopes::TEACHER.join(",")
  end

  def create
    auth_hash = request.env["omniauth.auth"]
    user      = User.find_by_auth_hash(auth_hash) || User.new

    user.assign_from_auth_hash(auth_hash)

    session[:user_id] = user.id

    url = session[:pre_login_destination] || organizations_path

    session[:current_scopes] = user.github_client_scopes

    redirect_to url
  end

  def lti_launch
    auth_hash = request.env["omniauth.auth"]
    session[:lti_uid] = auth_hash.uid

    # A simple before_filter will not work with this action,
    # as POST body from LTI launch _must_ be preserved
    if logged_in?
      redirect_to auth_lti_callback_path
    else
      session[:pre_login_destination] = auth_lti_callback_path
      authenticate_user! unless logged_in?
    end
  end

  def lti_callback
    lti_uid = session[:lti_uid]

    redirect_to organizations_path, alert: "LTI Launch Successful. [LMS User ID: #{lti_uid}]"
  end

  def destroy
    log_out
  end

  def failure
    redirect_to root_path, alert: "There was a problem authenticating with GitHub, please try again."
  end

  private

  def verify_lti_launch_enabled
    return not_found unless lti_launch_enabled?
  end
end
