class SessionsController < ApplicationController
  class LtiLaunchError < StandardError
    attr_reader :lti_message

    def initialize(message="There was an error launching GitHub Classroom. Please try again.", lti_message)
      super(message)
      @lti_message = lti_message
    end
  end

  skip_before_action :verify_authenticity_token,  only: %i[lti_launch]
  before_action      :allow_in_iframe,            only: %i[lti_launch]
  before_action      :verify_lti_launch_enabled,  only: %i[lti_setup lti_launch]

  rescue_from LtiLaunchError, with: :handle_lti_launch_error

  # rubocop:disable MethodLength
  # Called before validating an LTI launch request, and sets
  # required parameters for the Omniauth LTI strategy to succeed
  def lti_setup
    message = GitHubClassroom::LTI::MessageStore.construct_message(request.params)
    lti_configuration = LtiConfiguration.find_by(consumer_key: message.oauth_consumer_key)
    unless lti_configuration
      error_msg = "Configured credentials are not recognized by GitHub Classroom. Please ensure you've put in the
      proper `Consumer Key` and `Shared Secret` when configuring GitHub Classroom witin your Learning Management System."

      raise LtiLaunchError.new(message), error_msg
    end

    shared_secret = lti_configuration.shared_secret

    strategy = request.env["omniauth.strategy"]
    strategy.options.consumer_key = lti_configuration.consumer_key
    strategy.options.shared_secret = lti_configuration.shared_secret

    head :ok
  end
  # rubocop:enable MethodLength

  # After validating the LTI handshake is valid, we proceed with validating
  # the LTI message itself and scoping it to the relevant classroom organization
  def lti_launch
    auth_hash = request.env["omniauth.auth"]
    message = GitHubClassroom::LTI::MessageStore.construct_message(auth_hash.extra.raw_info)

    validate_message!(message)
    persist_message!(message)

    set_post_launch_url(message)

    render :lti_launch, layout: false, locals: { post_launch_url: @post_launch_url }
  end

  private

  def validate_message!(message)
    message_store = GitHubClassroom.lti_message_store(consumer_key: message.oauth_consumer_key)
    unless message_store.message_valid?(message)
      error_msg = "GitHub Classroom did not receive a valid launch message from your Learning Management System.
      Please re-launch GitHub Classroom from your Learning Management System and try again."

      raise LtiLaunchError.new(message), error_msg
    end

    message
  end

  def persist_message!(message)
    message_store = GitHubClassroom.lti_message_store(consumer_key: message.oauth_consumer_key)
    lti_configuration = LtiConfiguration.find_by(consumer_key: message.oauth_consumer_key)

    unless lti_configuration
      raise LtiLaunchError.new(message), "Configured credentials are not recognized by GitHub Classroom."
    end

    nonce = message_store.save_message(message)
    lti_configuration.cached_launch_message_nonce = nonce
    lti_configuration.save!

    message
  end

  def set_post_launch_url(message)
    linked_org = LtiConfiguration.find_by(consumer_key: message.oauth_consumer_key).organization
    if logged_in?
      @post_launch_url = complete_lti_configuration_url(linked_org)
    else
      session[:pre_login_destination] = complete_lti_configuration_url(linked_org)
      @post_launch_url = login_url
    end
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
