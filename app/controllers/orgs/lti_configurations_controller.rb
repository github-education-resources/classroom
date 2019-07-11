# frozen_string_literal: true

module Orgs
  class LtiConfigurationsController < Orgs::Controller
    before_action :ensure_lti_launch_flipper_is_enabled
    before_action :ensure_current_lti_configuration, only: :show

    def create
      # TODO: Create a new lti configuration for the current organization here
      # TODO: redirect_to lti_configuration_path(current_organization) after
    end

    def show; end

    def info; end

    def edit; end

    # TODO: this is a SPIKE to ensure this task is possible with all the pieces we currently have
    # this may not even be the controller this action (or actions, as the logic should most likely be split up) ends up in
    def import
      lti_configuration = current_organization.lti_configuration
      redirect_to info_lti_configuration_path(current_organization) unless lti_configuration.present?

      # TODO: the membership_service_url is consistent accross launches for a given LMS course,
      # so we should persist that url in postgres for a configuration so we don't have to look up
      # via a nonce stored on the temporary session
      lti_message_service = GitHubClassroom.lti_message_store(consumer_key: lti_configuration.consumer_key)
      raise 'LTI nonce not found on session -- Please launch from your LMS' unless session[:lti_nonce].present?

      lti_message = lti_message_service.get_message(session[:lti_nonce])
      raise 'No message found for nonce for lti_configuration' unless lti_message.present?

      membership_service_url = lti_message.custom_params["custom_context_memberships_url"]
      raise 'Membership service url not found on given lti message' unless membership_service_url.present?
      ## end TODO

      membership_service = LtiMembershipService.new(lti_configuration)
      membership = membership_service.get_membership(membership_service_url)

      # TODO: we have a multitude of choices for what we can import as the identifier,
      # and we should let the instructor choose
      members = membership.map(&:member)
      user_ids = members.map(&:user_id)
      names = members.map(&:name)

      # NOTE: this is an ugly workaround to pass via GET (see the diff in routes.rb to see why), but, it's a spike, so :)
      # In the real change we'll want to do this the proper way, obviously
      redirect_to :controller => :rosters, :action => :add_students, :params => { identifiers: names.join("\r\n") }
    end

    private

    def current_lti_configuration
      @current_lti_configuration ||= current_organization.lti_configuration
    end

    def ensure_current_lti_configuration
      redirect_to info_lti_configuration_path(current_organization) if current_lti_configuration.nil?
    end
  end
end
