# frozen_string_literal: true

module Shared
  class SharedJoinRosterView < ViewModel
    include Rails.application.routes.url_helpers

    attr_reader :roster, :invitation

    def octicon_name
      assignment_invitation? ? "person" : "organization"
    end

    def controller_name
      assignment_invitation? ? :assignment_invitations : :group_assignment_invitations
    end

    def skip_path
      if assignment_invitation?
        assignment_invitation_path(@invitation, roster: "ignore")
      else
        group_assignment_invitation_path(@invitation, roster: "ignore")
      end
    end

    private

    def assignment_invitation?
      @invitation.is_a?(AssignmentInvitation)
    end
  end
end
