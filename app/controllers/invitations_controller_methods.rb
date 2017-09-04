# frozen_string_literal: true

module InvitationsControllerMethods
  extend ActiveSupport::Concern

  included do
    layout "layouts/invitations"

    helper_method :current_assignment,
                  :current_invitation,
                  :current_submission,
                  :organization
  end

  def accept
    raise NotImplementedError
  end

  def show
    raise NotImplementedError
  end

  def success
    raise NotImplementedError
  end

  def join_roster
    entry = organization.roster.roster_entries.find(params[:roster_entry_id])
    entry.update_attributes!(user: current_user) unless user_on_roster?
  end

  private

  # We should redirect to the join_roster page if:
  # - The org has a roster
  # - The user is not on the roster
  # - The roster=ignore param is not set (we set this if the user chooses to "skip" joining a roster for now)
  def check_should_redirect_to_roster_page
    return if params[:roster] == "ignore" ||
              organization.roster.blank? ||
              user_on_roster?

    @roster = organization.roster

    render "join_roster"
  end

  def user_on_roster?
    roster = organization.roster
    RosterEntry.find_by(roster: roster, user: current_user)
  end

  # Private: Returns the Assignment or
  # GroupAssignment for the current_invitation.
  #
  # Returns and Assignment or GroupAssignment.
  def current_assignment
    return @current_assignment if defined?(@current_assignment)

    type = current_invitation.is_a?(AssignmentInvitation) ? :assignment : :group_assignment
    @current_assignment = current_invitation.send(type)
  end

  # Private: Returns the corresponding invitation.
  #
  # Returns and AssignmentInvitation or GroupAssignmentInvitation.
  def current_invitation
    raise NotImplementedError
  end

  # Private: Returns the submission for the current_user
  # if there is a submission.
  def current_submission
    raise NotImplementedError
  end

  # Prviate: Memoize the organization from the current_assignment.
  #
  # Returns an Organization.
  def organization
    @organization ||= current_assignment.organization
  end

  # Private: Return the GitHub API
  # token scopes needed for the controller.
  #
  # Example:
  #
  #  required_scopes
  #  # => ["user:email"]
  #
  # Returns an Array of Strings.
  def required_scopes
    raise NotImplementedError
  end
end
