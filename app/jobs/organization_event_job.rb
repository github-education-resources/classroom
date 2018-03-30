# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#organizationevent
class OrganizationEventJob < ApplicationJob
  queue_as :github_event

  def perform(payload_body)
    return true unless payload_body.dig("action") == "member_removed"

    github_user_id = payload_body.dig("membership", "user", "id")
    github_organization_id = payload_body.dig("organization", "id")
    @organization = Organization.find_by(github_id: github_organization_id)

    return false if @organization.users.count == 1

    @user = @organization.users.find_by(uid: github_user_id)

    return true unless @user

    transfer_assignments if user_owns_assignments?
    @organization.users.delete(@user)
  end

  def user_owns_assignments?
    @organization.all_assignments.map(&:creator_id).include? @user.id
  end

  def transfer_assignments
    new_owner = @organization.users.where.not(id: @user.id).first
    @organization.all_assignments.map do |a|
      a.creator_id = new_owner.id if a.creator_id == @user.id
      a.save
    end
  end
end
