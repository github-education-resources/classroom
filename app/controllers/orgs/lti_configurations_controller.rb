# frozen_string_literal: true

module Orgs
  class LtiConfigurationsController < Orgs::Controller
    before_action :ensure_lti_launch_flipper_is_enabled
    before_action :ensure_no_google_classroom
    before_action :ensure_current_lti_configuration, except: %i[new create]

    # rubocop:disable Metrics/MethodLength
    def create
      lti_configuration = LtiConfiguration.create(
        organization: current_organization,
        consumer_key: SecureRandom.uuid,
        shared_secret: SecureRandom.uuid
      )

      if lti_configuration.present?
        redirect_to lti_configuration_path(current_organization)
      else
        redirect_to new_lti_configuration_path(current_lti_configuration),
          alert: "There was a problem creating the configuration. Please try again later."
      end
    end
    # rubocop:enable Metrics/MethodLength

    def show; end

    def new; end

    def edit; end

    def update
      if current_lti_configuration.update_attributes(lti_configuration_params)
        flash[:success] = "The configuration was sucessfully updated."
        redirect_to lti_configuration_path(current_organization)
      else
        flash[:error] = "The configuration could not be updated at this time. Please try again."
        redirect_to edit_lti_configuration_path(current_organization)
      end
    end

    def destroy
      current_lti_configuration.destroy!

      redirect_to edit_organization_path(id: current_organization), alert: "LTI configuration deleted."
    end

    private

    def current_lti_configuration
      @current_lti_configuration ||= current_organization.lti_configuration
    end

    def ensure_current_lti_configuration
      redirect_to new_lti_configuration_path(current_organization) unless current_lti_configuration
    end

    def lti_configuration_params
      params.require(:lti_configuration).permit(:lms_link)
    end

    def ensure_no_google_classroom
      if current_organization.google_course_id
        redirect_to edit_organization_path(current_organization),
          alert: "An existing configuration exists. Please remove configuration before creating a new one."
      end
    end
  end
end
