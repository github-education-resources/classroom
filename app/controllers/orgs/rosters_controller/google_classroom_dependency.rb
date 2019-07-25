# frozen_string_literal: true

module Orgs
  class RostersController
    before_action :ensure_google_classroom_roster_import_is_enabled, only: %i[
      import_from_google_classroom sync_google_classroom
    ]
    before_action :authorize_google_classroom, only: %i[import_from_google_classroom sync_google_classroom]
    before_action :ensure_google_classroom_is_linked, only: %i[import_from_google_classroom sync_google_classroom]
    before_action :set_google_classroom, only: %i[import_from_google_classroom sync_google_classroom]
    before_action :ensure_no_lti_configuration, only: :import_from_google_classroom
    before_action :google_classroom_ensure_no_roster, only: :import_from_google_classroom

    def import_from_google_classroom
      students = list_google_classroom_students
      return unless students

      if students.blank?
        flash[:warning] = "No students were found in your Google Classroom. Please add students and try again."
        redirect_to roster_path(current_organization)
      else
        add_google_classroom_students(students)
      end
    end

    def sync_google_classroom
      unless current_organization.google_course_id
        flash[:error] = "No Google Classroom has been linked. Please link Google Classroom."
        return
      end

      latest_students = list_google_classroom_students
      latest_student_ids = latest_students.collect(&:user_id)
      current_student_ids  = current_roster.roster_entries.pluck(&:google_user_id)

      new_student_ids = latest_student_ids - current_student_ids
      new_students = latest_students.select { |s| new_student_ids.include? s.user_id }

      add_google_classroom_students(new_students)
    end
    # rubocop:enable Metrics/AbcSize

    private

    def ensure_google_classroom_is_linked
      return unless current_organization.google_course_id.nil?
      redirect_to google_classrooms_index_organization_path(current_organization),
        alert: "Please link a Google Classroom before syncing a roster."
    end

    def set_google_classroom
      @google_classroom_course = GoogleClassroomCourse.new(
        @google_classroom_service,
        current_organization.google_course_id
      )
    end

    def ensure_no_lti_configuration
      return unless current_organization.lti_configuration
      redirect_to edit_organization_path(current_organization),
        alert: "A LMS configuration already exists. Please remove configuration before creating a new one."
    end

    # Returns list of students in a google classroom with error checking
    def list_google_classroom_students
      @google_classroom_course.students || []
    rescue Google::Apis::AuthorizationError
      google_classroom_client = GitHubClassroom.google_classroom_client
      login_hint = current_user.github_user.login
      redirect_to google_classroom_client.get_authorization_url(login_hint: login_hint, request: request)
      nil
    rescue Google::Apis::ServerError, Google::Apis::ClientError
      flash[:error] = "Failed to fetch students from Google Classroom. Please try again later."
      redirect_to organization_path(current_organization)
      nil
    end
    # rubocop:enable Metrics/MethodLength

    # Add Google Classroom students to roster
    def add_google_classroom_students(students)
      names = students.map { |s| s.profile.name.full_name }
      user_ids = students.map(&:user_id)
      params[:identifiers] = names.join("\r\n")
      params[:google_user_ids] = user_ids

      if current_roster.nil?
        create
      else
        add_students
      end
    end

    def google_classroom_ensure_no_roster
      return unless current_organization.roster
      redirect_to edit_organization_path(current_organization),
        alert: "We are unable to link your classroom organization to Google Classroom"\
          "because a roster already exists. Please delete your current roster and try again."
    end
  end
end
