# frozen_string_literal: true

module InvitationHelper
  class << self
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
    #      :short_key => "aEE8Cq",
    #      :url  => "http://github.dev/assignment-invitations/7309ffd1f7b5e7af09dfcd11fab371d7",
    #      :short_url => "http://github.dev/a/aEE8Cq"
    #     }
    #
    # Returns a Hash of attributes
    def attributes(invitation, base_url)
      type = invitation.class.to_s.underscore

      {
        type: type,
        key: invitation.key,
        short_key: invitation.short_key,
        url: Rails.application.routes.url_helpers.send("#{type}_url".to_sym, id: invitation.key, host: base_url),
        short_url: short_url(invitation.short_key, type, base_url)
      }
    end

    private

    def short_url(short_key, type, base_url)
      if short_key
        Rails.application.routes.url_helpers.send(
          "#{type}_short_url".to_sym,
          short_key: short_key,
          host: base_url
        )
      else
        ''
      end
    end
  end
end
