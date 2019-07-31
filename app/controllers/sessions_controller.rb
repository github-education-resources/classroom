# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token,  only: %i[lti_launch]
  before_action      :allow_in_iframe,            only: %i[lti_launch]
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
    # TODO: There is so much tiny and important yet unrelated sutff happening in this method. Let's split it up.
    auth_hash = request.env["omniauth.auth"]

    # PART ONE: validating the launch message
    message_store = GitHubClassroom.lti_message_store(
      consumer_key: auth_hash.credentials.token
    )

    message = GitHubClassroom::LTI::MessageStore.construct_message(auth_hash.extra.raw_info)
    raise("invalid lti launch message") unless message_store.message_valid?(message)
    puts message

    # PART TWO: keying the launch message to the session
    nonce = message_store.save_message(message)
    session[:lti_nonce] = nonce

    # PART 2.5, we should untangle the login logic from the redirect logic

    # PART THREE: a spaghetti mess state machine determining how to interpret the launch message.
    # This should definitely be cleaned up (as it doesn't exist pre-spike), but it's a spike, so :)
    linked_org = LtiConfiguration.find_by_auth_hash(auth_hash).organization
    if logged_in?
      # If the organization has already been linked, determine whether the instructor is trying to
      # link an LMS assignment to an assignment on classroom or if the assignment is being launched
      # by a student to start their homework
      if(message.resource_link_id && linked_org.lti_configuration.lms_connection_status_linked?)
        linked_assignment = linked_org.assignments.find_by(lti_resource_link_id: message.resource_link_id)
        if(linked_assignment)
          @post_launch_url = assignment_invitation_path(id: linked_assignment.invitation.key) #organization_assignment_url(linked_org, linked_assignment)
        else
          @post_launch_url = select_lms_assignment_organization_url(linked_org, resource_id: message.resource_link_id)
        end
      else  # Organization is unliked, so finish linking the lti configuration
        linked_org.lti_configuration.lms_connection_status_linked!
        linked_org.lti_configuration.save!
        @post_launch_url = complete_lti_configuration_url(linked_org)
      end
    else
      # ... all of that mess of logic, without refactor, would also have to be re-put here, but because
      # it's a spike, let's pretend a user is always authenticated with GitHub pre-launch :)
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

  def verify_lti_launch_enabled
    return not_found unless lti_launch_enabled?
  end
end
