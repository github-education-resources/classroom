# frozen_string_literal: true

module Orgs
  class LtiConfigurationsController < Orgs::Controller
    before_action :ensure_lti_launch_flipper_is_enabled
    before_action :ensure_current_lti_configuration,             except: %i[new create]

    def create
      # Create a new lti configuration for the current organization here
      # redirect_to lti_configuration_path(current_organization) after
    end

    private

    def current_lti_configuration
      @current_lti_configuration ||= current_organization.lti_configuration
    end

    def ensure_current_lti_configuration
      redirect_to new_lti_configuration_path(current_organization) if current_lti_configuration.nil?
    end
  end
end
