# frozen_string_literal: true

class ShortUrlController < ApplicationController
  skip_before_action :authenticate_user!

  def assignment_invitation
    invitation = AssignmentInvitation.find_by(short_key: key)

    not_found unless invitation

    redirect_to invitation_url(invitation, :assignment_invitation)
  end

  def group_assignment_invitation
    invitation = GroupAssignmentInvitation.find_by(short_key: key)

    not_found unless invitation

    redirect_to invitation_url(invitation, :group_assignment_invitation)
  end

  private

  def invitation_url(invitation, type)
    Rails.application.routes.url_helpers.send("#{type}_url".to_sym, id: invitation.key, host: request.base_url)
  end

  def key
    params[:short_key]
  end
end
