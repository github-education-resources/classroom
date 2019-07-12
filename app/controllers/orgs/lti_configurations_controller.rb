# frozen_string_literal: true

module Orgs
  class LtiConfigurationsController < Orgs::Controller
    before_action :ensure_lti_launch_flipper_is_enabled
    before_action :ensure_current_lti_configuration, only: :show

    def create
      lti_configuration = LtiConfiguration.create({
        organization: current_organization,
        consumer_key: SecureRandom.uuid,
        shared_secret: SecureRandom.uuid
      })

      if lti_configuration.present?
        redirect_to lti_configuration_path(current_organization)
      else
        redirect_to new_lti_configuration_path(current_lti_configuration),
          alert: "There was a problem creating the configuration. Please try again."
      end
    end

    def show; end

    def new; end

    def edit
      if @current_lti_configuration.update_attributes(lti_configuration_params)
        flash[:success] = "Your LMS configuration has been created!"
      else
        flash[:error] = "Your LMS configuration could not be created. Please try again."
      end
      render :show
    end

    def destroy
      current_lti_configuration.destroy!

      redirect_to edit_organization_path(id: current_organization), alert: "LTI Configuration Deleted."
    end

    private

    def current_lti_configuration
      @current_lti_configuration ||= current_organization.lti_configuration
    end

    def ensure_current_lti_configuration
      redirect_to new_lti_configuration_path(current_organization) if current_lti_configuration.nil?
    end

    def lti_configuration_params
      params.require(:lti_configuration).permit(:lms_link)
    end
  end
end
