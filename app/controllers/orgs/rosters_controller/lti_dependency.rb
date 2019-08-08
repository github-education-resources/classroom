# frozen_string_literal: true

module Orgs
  class RostersController
    class LtiImportError < StandardError; end

    skip_before_action :ensure_current_roster, only: [:import_from_lms]
    before_action :ensure_lti_launch_flipper_is_enabled, only: [:import_from_lms]
    before_action :ensure_lti_configuration, only: [:import_from_lms]

    rescue_from LtiImportError, with: :handle_lms_import_error

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable AbcSize
    def import_from_lms
      students = lms_membership
      @identifiers = {
        "User IDs": students.map(&:user_id),
        "Names": students.map(&:name),
        "Emails": students.map(&:email)
      }.select { |_, v| v.any? }

      GitHubClassroom.statsd.increment("lti_configuration.import")

      lms_name = current_organization.lti_configuration.lms_name(default_name: "your Learning Management System")
      respond_to do |format|
        format.js { render :import_from_lms, locals: { lms_name: lms_name } }
        format.html { render :import_from_lms, locals: { lms_name: lms_name } }
      end
    end
    # rubocop:enable AbcSize
    # rubocop:enable Metrics/MethodLength

    private

    def ensure_lti_configuration
      redirect_to link_lms_organization_path(current_organization) unless current_organization.lti_configuration
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def lms_membership
      unless current_organization.lti_configuration.supports_membership_service?
        lms_name = current_organization.lti_configuration.lms_name(default_name: "your Learning Management System")
        msg = "GitHub Classroom does not have access to your course roster on #{lms_name}. Please ensure that
        you've allowed GitHub Classroom to retrieve your course membership from #{lms_name} and try again."

        raise LtiImportError, msg
      end

      membership_service = GitHubClassroom::LTI::MembershipService.new(
        current_organization.lti_configuration.context_membership_url,
        current_organization.lti_configuration.consumer_key,
        current_organization.lti_configuration.shared_secret
      )

      begin
        membership_service.students
      rescue Faraday::ClientError, JSON::ParserError
        lms_name = current_organization.lti_configuration.lms_name(default_name: "your Learning Management System")
        msg = "GitHub Classroom is unable to fetch membership from #{lms_name} at this time. If the problem persists,
        re-launch GitHub Classroom from your Learning Management System and try again."

        raise LtiImportError, msg
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def handle_lms_import_error(err)
      respond_to do |f|
        f.html { redirect_to roster_path(current_organization), alert: err.message }
        f.js do
          flash.now[:alert] = err.message
          render :import_from_lms, status: :unprocessable_entity
        end
      end
    end
  end
end
