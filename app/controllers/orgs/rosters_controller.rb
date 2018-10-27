# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Orgs
  class RostersController < Orgs::Controller
    before_action :ensure_student_identifier_flipper_is_enabled

    before_action :ensure_current_roster,             except: %i[new create]
    before_action :ensure_current_roster_entry,       except: %i[show new create remove_organization add_students]
    before_action :ensure_enough_members_in_roster,   only: [:delete_entry]
    before_action :ensure_allowed_to_access_grouping, only: [:show]

    helper_method :current_roster, :unlinked_users

    # rubocop:disable AbcSize
    def show
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
        identifier_name: params[:identifier_name],
        identifiers: params[:identifiers]
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

      current_roster_entry.update_attributes!(user_id: user_id)

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

      begin
        entries = RosterEntry.create_entries(identifiers: identifiers, roster: current_roster)

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
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

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
  end
end
# rubocop:enable Metrics/ClassLength
