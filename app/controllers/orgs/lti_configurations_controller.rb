# frozen_string_literal: true

module Orgs
  class LtiConfigurationsController < Orgs::Controller
    before_action :ensure_lti_launch_flipper_is_enabled
    before_action :ensure_current_lti_configuration, only: :show

    def create
      lti_configuration = LtiConfiguration.new
      lti_configuration.organization = current_organization
      lti_configuration.consumer_key = SecureRandom.uuid
      lti_configuration.shared_secret = SecureRandom.uuid
      lti_configuration.save!
      redirect_to lti_configuration_path(current_organization)
    end

    def show; end

    def info; end

    def edit; end

    def destroy; end

    private

    def current_lti_configuration
      @current_lti_configuration ||= current_organization.lti_configuration
    end

    def ensure_current_lti_configuration
      redirect_to info_lti_configuration_path(current_organization) if current_lti_configuration.nil?
    end
  end
end
