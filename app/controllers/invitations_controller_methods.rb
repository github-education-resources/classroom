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

  private

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
