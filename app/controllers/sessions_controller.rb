# frozen_string_literal: true

class SessionsController < ApplicationController
  class LtiLaunchError < StandardError
    attr_reader :lti_message

    def initialize(message="There was an error launching GitHub Classroom. Please try again.", lti_message)
      super(message)
      @lti_message = lti_message
    end
  end

  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token,  only: %i[lti_launch]
  before_action      :allow_in_iframe,            only: %i[lti_launch]
  before_action      :verify_lti_launch_enabled,  only: %i[lti_setup lti_launch]

  rescue_from LtiLaunchError, with: :handle_lti_launch_error

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
    raise LtiLaunchError.new(message) unless message_store.message_valid?(message)

    lti_configuration = LtiConfiguration.find_by_auth_hash(auth_hash)
    raise LtiLaunchError.new(message), "Configured consumer key is not associated with GitHub Classroom." unless lti_configuration
    lti_configuration.cached_launch_message_nonce = message_store.save_message(message)
    lti_configuration.save!

    linked_org = lti_configuration.organization
    if logged_in?
      @post_launch_url = complete_lti_configuration_url(linked_org)
    else
      @post_launch_url = login_url
      session[:pre_login_destination] = complete_lti_configuration_url(linked_org)
    end
    render :lti_launch, layout: false, locals: { post_launch_url: @post_launch_url }
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

  def allow_in_iframe
    response.headers.delete "X-Frame-Options"
  end

  def verify_lti_launch_enabled
    return not_found unless lti_launch_enabled?
  end

  def handle_lti_launch_error(err)
    error_msg = err.message
    message = err.lti_message

    if message.launch_presentation_return_url
      error_params = { lti_errormsg: error_msg }.to_param
      callback_url = "#{message.launch_presentation_return_url}?#{error_params}"

      return redirect_to callback_url
    end
    render :lti_launch, layout: false, locals: { error: error_msg }
  end
end
