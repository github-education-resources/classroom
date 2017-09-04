# frozen_string_literal: true

module Orgs
  class RostersController < Orgs::Controller
    before_action :ensure_student_identifier_flipper_is_enabled

    before_action :ensure_current_roster,           except: %i[new create]
    before_action :ensure_current_roster_entry,     except: %i[show new create remove_organization add_student]
    before_action :ensure_enough_members_in_roster, only: [:delete_entry]

    helper_method :current_roster, :unlinked_users

    def show; end

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
      user = User.find(params[:user_id])

      # Make sure the user is on the list
      raise ActiveRecord::ActiveRecordError unless unlinked_users.include?(user)
      current_roster_entry.update_attributes!(user_id: user.id)

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

    def add_student
      roster_entry = RosterEntry.create(identifier: params[:identifier], roster: current_roster)

      if roster_entry.valid?
        flash[:success] = "Student created!"
      else
        flash[:error] = "An error has occured, please try again."
      end

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

    # An unlinked user is a user who:
    # - Is a user on an assignment or group assignment belonging to the org
    # - Is not on the organization roster
    #
    # rubocop:disable Metrics/AbcSize
    def unlinked_users
      return @unlinked_users if defined?(@unlinked_users)

      assignment_users       = current_organization.assignments.map(&:users).flatten.uniq
      roster_entry_users     = current_roster.roster_entries.map(&:user).compact
      group_assignment_users = current_organization.repo_accesses.map(&:user)

      @unlinked_users = (group_assignment_users + assignment_users).uniq - roster_entry_users
    end
    # rubocop:enable Metrics/AbcSize
  end
end
