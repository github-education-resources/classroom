# frozen_string_literal: true

module Orgs
  class RostersController
    class LtiImportError < StandardError; end

    skip_before_action :ensure_current_roster, only: [:import_from_lms]
    before_action :ensure_lti_configuration, only: [:import_from_lms]

    rescue_from LtiImportError, with: :handle_lms_import_error

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable AbcSize
    def import_from_lms
      lms_name = current_organization.lti_configuration.lms_name(default_name: "your learning management system")

      all_students = lms_membership
      new_students = filter_new_students(all_students)
      if all_students.present? && new_students.empty?
        raise LtiImportError, "No students created. Your roster is already up to date with #{lms_name}."
      end

      @student_ids = new_students.map(&:user_id)
      @identifiers = {
        "User IDs": @student_ids,
        "Names": new_students.map(&:name),
        "Emails": new_students.map(&:email)
      }.select { |_, v| v.any? }

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

    def filter_new_students(all_students)
      all_student_ids = all_students.map(&:user_id)
      existing_student_ids = RosterEntry.where(roster: current_roster).pluck(:lms_user_id)

      new_student_ids = all_student_ids - existing_student_ids
      new_students = all_students.select { |student| new_student_ids.include?(student.user_id) }
      new_students
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def lms_membership
      unless current_organization.lti_configuration.supports_membership_service?
        lms_name = current_organization.lti_configuration.lms_name(default_name: "your learning management system")
        msg = "GitHub Classroom does not have access to your course roster on #{lms_name}. Please ensure that
        you've allowed GitHub Classroom to retrieve your course membership from #{lms_name} and try again."

        raise LtiImportError, msg
      end

      membership_service = GitHubClassroom::LTI::MembershipService.new(
        current_organization.lti_configuration.context_membership_url,
        current_organization.lti_configuration.consumer_key,
        current_organization.lti_configuration.shared_secret,
        lti_version: current_organization.lti_configuration.lti_version
      )

      begin
        membership_service.students(body_params: current_organization.lti_configuration.context_membership_body_params)
      rescue Faraday::ClientError, JSON::ParserError => error
        report_error(error)

        lms_name = current_organization.lti_configuration.lms_name(default_name: "your learning management system")
        msg = "GitHub Classroom is unable to fetch membership from #{lms_name} at this time. If the problem persists,
        re-launch GitHub Classroom from your learning management system and try again."

        raise LtiImportError, msg
      end
    end

    def report_error(error)
      error_context = {}.tap do |e|
        e[:context_membership_url] = current_organization.lti_configuration.context_membership_url
        e[:lti_version] = current_organization.lti_configuration.lti_version
        e[:lms_type] = current_organization.lti_configuration.lms_type
      end
      Failbot.report!(error, error_context)
    end

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
