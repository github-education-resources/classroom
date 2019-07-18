# frozen_string_literal: true

require "google/apis/classroom_v1"

# rubocop:disable Metrics/ClassLength
module Orgs
  class RostersController < Orgs::Controller
    before_action :ensure_google_classroom_roster_import_is_enabled, only: %i[
      import_from_google_classroom
      select_google_classroom
      search_google_classroom
      sync_google_classroom
      unlink_google_classroom
    ]
    before_action :ensure_current_roster, except: %i[
      new
      create
      select_google_classroom
      import_from_google_classroom
      import_from_lms
      search_google_classroom
    ]
    before_action :redirect_if_roster_exists, only: [:new]
    before_action :ensure_current_roster_entry,       only:   %i[link unlink delete_entry download_roster]
    before_action :ensure_enough_members_in_roster,   only:   [:delete_entry]
    before_action :ensure_allowed_to_access_grouping, only:   [:show]
    before_action :authorize_google_classroom, only:   %i[
      import_from_google_classroom
      select_google_classroom
      search_google_classroom
      sync_google_classroom
      unlink_google_classroom
    ]
    before_action :google_classroom_ensure_no_roster, only: %i[
      select_google_classroom
    ]
    before_action :ensure_lti_launch_flipper_is_enabled, only: [:import_from_lms]

    helper_method :current_roster, :unlinked_users, :authorize_google_classroom

    # rubocop:disable AbcSize
    def show
      @google_course_name = current_organization_google_course_name

      @roster_entries = current_roster.roster_entries
        .includes(:user)
        .order(:identifier)
        .page(params[:roster_entries_page])

      @current_unlinked_users = User
        .where(id: unlinked_user_ids)
        .order(:id)
        .page(params[:unlinked_users_page])

      download_roster if params.dig("format")
    end
    # rubocop:enable AbcSize

    def new
      @roster = Roster.new
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def create
      result = Roster::Creator.perform(
        organization: current_organization,
        identifiers: params[:identifiers],
        idenifier_name: params[:identifier_name],
        google_user_ids: params[:google_user_ids]
      )

      # Set the object so that we can see errors when rendering :new
      @roster = result.roster

      if result.success?
        GitHubClassroom.statsd.increment("roster.create")

        flash[:success] = \
          "Your classroom roster has been saved! Manage it <a href='#{roster_url(current_organization)}'>here</a>."

        redirect_to organization_path(current_organization)
      else
        render :new
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def remove_organization
      Organization.transaction do
        current_organization.update_attributes!(roster_id: nil)
        current_roster.destroy! if Organization.where(roster_id: current_roster.id).count.zero?
      end

      flash[:success] = "Roster successfully deleted!"
    rescue ActiveRecord::RecordInvalid
      flash[:error] = "An error has occured while trying to delete the roster. Please try again."
    ensure
      redirect_to organization_path(current_organization)
    end
    # rubocop:enable Metrics/AbcSize

    def link
      # Make sure the user is on the list
      user_id = params[:user_id].to_i
      raise ActiveRecord::ActiveRecordError unless unlinked_user_ids.include?(user_id)

      current_roster_entry.update(user_id: user_id)

      flash[:success] = "Student and GitHub account linked!"
    rescue ActiveRecord::ActiveRecordError
      flash[:error] = "An error has occured, please try again."
    ensure
      redirect_to roster_path(current_organization)
    end

    def unlink
      current_roster_entry.update_attributes!(user_id: nil)

      flash[:success] = "Student and GitHub account unlinked!"
    rescue ActiveRecord::ActiveRecordError
      flash[:error] = "An error has occured, please try again."
    ensure
      redirect_to roster_path(current_organization)
    end

    def delete_entry
      current_roster_entry.destroy!

      flash[:success] = "Student successfully removed from roster!"
    rescue ActiveRecord::ActiveRecordError
      flash[:error] = "An error has occured, please try again."
    ensure
      redirect_to roster_path(current_organization)
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def add_students
      identifiers = params[:identifiers].split("\r\n").reject(&:blank?).uniq
      google_ids = params[:google_user_ids] || []

      begin
        entries = RosterEntry.create_entries(
          identifiers: identifiers,
          roster: current_roster,
          google_user_ids: google_ids
        )

        if entries.empty?
          flash[:warning] = "No students created."
        elsif entries.length == identifiers.length
          flash[:success] = "Students created."
        else
          flash[:success] = "Students created. Some duplicates have been omitted."
        end
      rescue RosterEntry::IdentifierCreationError
        flash[:error] = "An error has occured. Please try again."
      end

      redirect_to roster_path(current_organization)
    end

    def download_roster
      grouping = current_organization.groupings.find(params[:grouping]) if params[:grouping]

      user_to_groups = get_user_to_group_hash(grouping)

      @roster_entries = @current_roster.roster_entries.includes(:user).order(:identifier)
      respond_to do |format|
        format.csv do
          send_data(
            @roster_entries.to_csv(user_to_groups),
            filename:    "classroom_roster.csv",
            disposition: "attachment"
          )
        end
      end
    end

    def import_from_lms
      lti_configuration = current_organization.lti_configuration
      return redirect_to new_lti_configuration_path(current_organization) unless lti_configuration

      membership_service_url = lti_configuration.context_membership_url(nonce: session[:lti_nonce])
      unless membership_service_url
        err = "GitHub Classroom is not configured properly on your Learning Management System.
        Please ensure the integration is configured properly and try again."

        return respond_to do |f|
          f.js { flash.now[:alert] = err }
          f.html do
            return redirect_to roster_path(current_organization), alert: err
          end
        end
      end

      membership_service = GitHubClassroom::LTI::MembershipService.new(
        membership_service_url,
        lti_configuration.consumer_key,
        lti_configuration.shared_secret
      )

      begin
        membership = membership_service.students

        members = membership.map(&:member)
        @identifiers = {
          "User IDs": members.map(&:user_id),
          "Names": members.map(&:name),
          "Emails": members.map(&:email)
        }

        respond_to do |format|
          format.js
          format.html
        end
      rescue
        err = "Unable to fetch membership from your Learning Management System at this time. Please try again later."

        return respond_to do |f|
          f.js { flash.now[:alert] = err }
          f.html do
            return redirect_to roster_path(current_organization), alert: err
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def select_google_classroom
      @google_classroom_courses = fetch_all_google_classrooms
    end

    def search_google_classroom
      courses_found = fetch_all_google_classrooms.select do |course|
        course.name.downcase.include? params[:query].downcase
      end

      respond_to do |format|
        format.html do
          render partial: "orgs/rosters/google_classroom_collection",
                 locals: { courses: courses_found }
        end
      end
    end

    def import_from_google_classroom
      students = list_google_classroom_students(params[:course_id])
      return unless students

      if students.blank?
        flash[:warning] = "No students were found in your Google Classroom. Please add students and try again."
        redirect_to roster_path(current_organization)
      else
        current_organization.update(google_course_id: params[:course_id])
        add_google_classroom_students(students)
      end
    end

    # rubocop:disable Metrics/AbcSize
    def sync_google_classroom
      unless current_organization.google_course_id
        flash[:error] = "No Google Classroom has been linked. Please link Google Classroom."
        return
      end

      latest_students = list_google_classroom_students(current_organization.google_course_id)
      latest_student_ids = latest_students.collect(&:user_id)
      current_student_ids = current_roster.roster_entries.collect(&:google_user_id)

      new_student_ids = latest_student_ids - current_student_ids
      new_students = latest_students.select { |s| new_student_ids.include? s.user_id }

      add_google_classroom_students(new_students)
    end
    # rubocop:enable Metrics/AbcSize

    def unlink_google_classroom
      current_organization.update!(google_course_id: nil)
      flash[:success] = "Removed link to Google Classroom. No students were removed from your roster."

      redirect_to roster_path(current_organization)
    end

    private

    def current_roster
      return @current_roster if defined?(@current_roster)
      @current_roster = current_organization.roster
    end

    def current_roster_entry
      return @current_roster_entry if defined?(@current_roster_entry)
      @current_roster_entry = current_roster.roster_entries.find_by(id: params[:roster_entry_id])
    end

    def ensure_current_roster
      redirect_to new_roster_url(current_organization) if current_roster.nil?
    end

    def ensure_current_roster_entry
      not_found if current_roster_entry.nil?
    end

    def ensure_enough_members_in_roster
      return if current_roster.roster_entries.count > 1

      flash[:error] = "You cannot delete the last member of your roster!"
      redirect_to roster_url(current_organization)
    end

    def ensure_allowed_to_access_grouping
      return if params[:grouping].nil?

      not_found unless Grouping.find(params[:grouping]).organization_id == current_organization.id
    end

    # An unlinked user is a user who:
    # - Is a user on an assignment or group assignment belonging to the org
    # - Is not on the organization roster
    #
    # rubocop:disable Metrics/AbcSize
    def unlinked_user_ids
      return @unlinked_user_ids if defined?(@unlinked_user_ids)

      assignment_query = "assignment_repos.assignment_id IN (?) AND assignment_repos.user_id IS NOT NULL"
      assignments_ids  = current_organization.assignments.pluck(:id)
      assignment_users = AssignmentRepo.where(assignment_query, assignments_ids).pluck(:user_id).uniq

      roster_query       = "roster_entries.roster_id = ? AND roster_entries.user_id IS NOT NULL"
      roster_entry_users = RosterEntry.where(roster_query, current_roster.id).pluck(:user_id)

      group_assignment_query = "repo_accesses.organization_id = ? AND repo_accesses.user_id IS NOT NULL"
      group_assignment_users = RepoAccess.where(group_assignment_query, current_organization.id).pluck(:user_id)

      @unlinked_user_ids = (group_assignment_users + assignment_users).uniq - roster_entry_users
    end
    # rubocop:enable Metrics/AbcSize

    def unlinked_users
      return @unlinked_users if defined?(@unlinked_users)
      @unlinked_users = []

      result = User.where(id: unlinked_user_ids)

      result.each do |user|
        @unlinked_users.push(user)
      end

      @unlinked_users
    end

    # Maps user_ids to group names
    # If no grouping is specified it returns an empty hash
    def get_user_to_group_hash(grouping)
      mapping = {}
      return mapping unless grouping

      grouping.groups.each do |group|
        group.repo_accesses.map(&:user_id).each do |id|
          mapping[id] = group.title
        end
      end

      mapping
    end

    # Returns name of the linked google course to current organization (for syncing rosters)
    def current_organization_google_course_name
      return unless current_organization.google_course_id
      authorize_google_classroom
      course = @google_classroom_service.get_course(current_organization.google_course_id)
      course&.name
    rescue Google::Apis::Error
      nil
    end

    # Returns list of students in a google classroom with error checking
    # rubocop:disable Metrics/MethodLength
    def list_google_classroom_students(course_id)
      response = @google_classroom_service.list_course_students(course_id)
      response.students ||= []
      response.students
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

    # Fetches all courses for a Google Account
    def fetch_all_google_classrooms
      next_page = nil
      courses = []
      loop do
        response = @google_classroom_service.list_courses(page_size: 20, page_token: next_page)
        courses.push(*response.courses)

        next_page = response.next_page_token
        break unless next_page
      end

      courses
    end

    # Authorizes current user through Google and sets google_classroom_service
    # Used as a before_action before routes which require Google authorization
    def authorize_google_classroom
      google_classroom_client = GitHubClassroom.google_classroom_client
      unless user_google_classroom_credentials
        login_hint = current_user.github_user.login
        redirect_to google_classroom_client.get_authorization_url(login_hint: login_hint, request: request)
      end

      @google_classroom_service = Google::Apis::ClassroomV1::ClassroomService.new
      @google_classroom_service.client_options.application_name = "GitHub Classroom"
      @google_classroom_service.authorization = user_google_classroom_credentials
    end

    # Helper method for getting current user's google classroom credentials
    def user_google_classroom_credentials
      google_classroom_client = GitHubClassroom.google_classroom_client
      user_id = current_user.uid.to_s

      google_classroom_client.get_credentials(user_id, request)
    rescue Signet::AuthorizationError
      # Will reauthorize upstream
      nil
    end

    def redirect_if_roster_exists
      redirect_to roster_url(current_organization) if current_organization.roster.present?
    end

    def google_classroom_ensure_no_roster
      return unless current_organization.roster
      redirect_to edit_organization_path(current_organization),
        alert: "We are unable to link your classroom organization to Google Classroom"\
          "because a roster already exists. Please delete your current roster and try again."
    end
  end
end
# rubocop:enable Metrics/ClassLength
