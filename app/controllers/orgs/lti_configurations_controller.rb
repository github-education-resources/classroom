# frozen_string_literal: true

module Orgs
  class LtiConfigurationsController < Orgs::Controller
    before_action :ensure_lti_launch_flipper_is_enabled
    before_action :ensure_no_google_classroom
    before_action :ensure_current_lti_configuration, only: :show

    def create
      # TODO: Create a new lti configuration for the current organization here
      # TODO: redirect_to lti_configuration_path(current_organization) after
    end

    def show; end

    def info; end

    def edit; end

    private

    def current_lti_configuration
      @current_lti_configuration ||= current_organization.lti_configuration
    end

    def ensure_current_lti_configuration
      redirect_to info_lti_configuration_path(current_organization) if current_lti_configuration.nil?
    end

    def ensure_no_google_classroom
      if current_organization.google_course_id
        redirect_to edit_organization_path(current_organization),
          alert: "An existing configuration exists. Please remove configuration before creating a new one."
      end
    end
  end
end
