# frozen_string_literal: true

module InvitationHelper
  # Public: Return the attributes needed
  # to render the invitation copy url parial
  #
  # invitation - An AssignmentInvitation or GroupAssignmentInvitation
  #
  # Examples
  #
  # InvitationHelper.attributes(assignment.invitation, request.base_url)
  # #=> {
  #      :type => "assignment_invitation",
  #      :key  => "7309ffd1f7b5e7af09dfcd11fab371d7",
  #      :url  => "http://github.dev/assignment-invitations/7309ffd1f7b5e7af09dfcd11fab371d7"
  #     }
  #
  # Returns a Hash of attributes
  def self.attributes(invitation, base_url)
    type = invitation.class.to_s.underscore

    {
      type: type,
      key: invitation.key,
      url: Rails.application.routes.url_helpers.send("#{type}_url".to_sym, id: invitation.key, host: base_url)
    }
  end
end
