# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token,  only: [:lti_launch]
  before_action      :verify_lti_launch_enabled,  only: %i[lti_setup lti_launch]

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

  # rubocop:disable AbcSize
  def lti_setup
    consumer_key = request.params["oauth_consumer_key"]
    raise(ActionController::BadRequest, "consumer_key must be present") if consumer_key.blank?

    lti_configuration = LtiConfiguration.find_by(consumer_key: consumer_key)
    raise(ActionController::BadRequest, "missing corresponding lti configuration") if lti_configuration.blank?

    shared_secret = lti_configuration.shared_secret

    strategy = request.env["omniauth.strategy"]
    raise(ActionController::BadRequest, "request.env[\"omniauth.strategy\"] must be set") if strategy.blank?

    strategy.options.consumer_key = consumer_key
    strategy.options.shared_secret = shared_secret

    head :ok
  end
  # rubocop:enable AbcSize

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def lti_launch
    auth_hash = request.env["omniauth.auth"]
    message_store = GitHubClassroom.lti_message_store(
      consumer_key: auth_hash.credentials.token
    )

    message = GitHubClassroom::LTI::MessageStore.construct_message(auth_hash.extra.raw_info)
    raise("invalid lti launch message") unless message_store.message_valid?(message)

    nonce = message_store.save_message(message)
    session[:lti_nonce] = nonce

    linked_org = LtiConfiguration.find_by_auth_hash(auth_hash).organization

    if logged_in?
      redirect_to edit_organization_path(id: linked_org.slug), alert: "LTI Launch Successful. [Nonce: #{nonce}]"
    else
      session[:pre_login_destination] = edit_organization_path(id: linked_org.slug)
      authenticate_user!
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

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
