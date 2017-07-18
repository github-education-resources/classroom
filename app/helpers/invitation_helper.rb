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
    #      :url  => "http://github.dev/assignment-invitations/7309ffd1f7b5e7af09dfcd11fab371d7",
    #     }
    #
    # Returns a Hash of attributes
    def attributes(invitation, base_url)
      {
        type: invitation_type(invitation),
        key: invitation_key(invitation),
        url: invitation_url(invitation: invitation, base_url: base_url)
      }
    end

    private

    def invitation_key(invitation)
      return invitation.short_key if invitation.short_key.present?
      invitation.key
    end

    def invitation_type(invitation)
      invitation.class.to_s.underscore
    end

    # rubocop:disable Metrics/MethodLength
    def invitation_url(invitation:, base_url:)
      type = invitation_type(invitation)
      url  = nil

      options = {}.tap do |opts|
        opts[:host] = base_url

        url = if invitation.short_key.present?
                opts[:short_key] = invitation.short_key
                "#{type}_short_url"
              else
                opts[:id] = invitation.key
                "#{type}_url"
              end
      end

      Rails.application.routes.url_helpers.send(url.to_sym, options)
    end
    # rubocop:enable Metrics/MethodLength
  end
end
