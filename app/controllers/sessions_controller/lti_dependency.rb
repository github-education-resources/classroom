# frozen_string_literal: true

class SessionsController < ApplicationController
  class LtiLaunchError < StandardError
    attr_reader :lti_message

    def initialize(lti_message)
      super(nil)
      @lti_message = lti_message
    end
  end

  skip_before_action :verify_authenticity_token,  only: %i[lti_launch]
  before_action      :allow_in_iframe,            only: %i[lti_launch]

  rescue_from LtiLaunchError, with: :handle_lti_launch_error

  # rubocop:disable AbcSize
  # Called before validating an LTI launch request, and sets
  # required parameters for the Omniauth LTI strategy to succeed
  def lti_setup
    lti_configuration = LtiConfiguration.find_by(consumer_key: request.params["oauth_consumer_key"])
    raise LtiLaunchError.new(nil), "Configured consumer key is invalid." unless lti_configuration

    strategy = request.env["omniauth.strategy"]
    raise LtiLaunchError.new(nil), "Incoming request is not a LTI launch" unless strategy

    strategy.options.consumer_key = lti_configuration.consumer_key
    strategy.options.shared_secret = lti_configuration.shared_secret
    head :ok
  end
  # rubocop:enable AbcSize

  # After validating the LTI handshake is valid, we proceed with validating
  # the LTI message itself and scoping it to the relevant classroom organization
  def lti_launch
    auth_hash = request.env["omniauth.auth"]
    consumer_key = auth_hash.credentials.token
    message = GitHubClassroom::LTI::MessageStore.construct_message(auth_hash.extra.raw_info)

    validate_message!(consumer_key, message)
    persist_message!(consumer_key, message)

    update_post_launch_url(consumer_key)
    render :lti_launch, layout: false, locals: { post_launch_url: @post_launch_url }
  end

  # Called if the LTI OmniAuth handshake fails verification
  def lti_failure
    message = IMS::LTI::Models::Messages::BasicLTILaunchRequest.new(params)
    error_msg = "The launch credentials could not be authorized. Ensure you've entered the correct \"consumer key\"
    and \"shared secret\" when configuring GitHub Classroom within your learning management system."

    raise LtiLaunchError.new(message), error_msg
  end

  private

  def validate_message!(consumer_key, message)
    message_store = GitHubClassroom.lti_message_store(consumer_key: consumer_key)
    unless message_store.message_valid?(message)
      error_msg = "The launch message from your Learning Management system could not be validated.
      Please re-launch GitHub Classroom from your learning management system."

      raise LtiLaunchError.new(message), error_msg
    end

    message
  end

  def persist_message!(consumer_key, message)
    message_store = GitHubClassroom.lti_message_store(consumer_key: consumer_key)
    lti_configuration = LtiConfiguration.find_by(consumer_key: consumer_key)

    nonce = message_store.save_message(message)
    lti_configuration.cached_launch_message_nonce = nonce
    lti_configuration.save!

    message
  end

  def update_post_launch_url(consumer_key)
    linked_org = LtiConfiguration.find_by(consumer_key: consumer_key).organization
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

    if message.try(:launch_presentation_return_url)
      error_params = { lti_errormsg: error_msg }.to_param
      callback_url = URI.parse(message.launch_presentation_return_url)
      query = callback_url.query

      callback_url.query = query ? "#{query}&#{error_params}" : error_params
      return redirect_to callback_url.to_s
    end

    render :lti_launch, layout: false, locals: { error: error_msg }
  end
end
