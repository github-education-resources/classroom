# frozen_string_literal: true

class ShortUrlController < ApplicationController
  def accept_assignment
    assignment = AssignmentInvitation.find_by(short_key: key)
    respond(assignment)
  end

  def accept_group_assignment
    assignment = GroupAssignmentInvitation.find_by(short_key: key)
    respond(assignment)
  end

  private

  def respond(assignment)
    not_found unless assignment

    redirect_to invitation_url(assignment)
  end

  def invitation_url(assignment)
    Rails.application.url_helpers.send("#{type}_url".to_sym, id: assignment.invitation.key, host: base_url)
  end

  def key
    params[:short_key]
  end
end
