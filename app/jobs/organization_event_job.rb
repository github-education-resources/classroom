# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#organizationevent
class OrganizationEventJob < ApplicationJob
  queue_as :github_event

  # rubocop:disable Metrics/AbcSize
  def perform(payload_body)
    return true unless payload_body.dig("action") == "member_removed"

    github_user_id = payload_body.dig("membership", "user", "id")
    github_organization_id = payload_body.dig("organization", "id")
    @organization = Organization.find_by(github_id: github_organization_id)

    return false if @organization.blank?
    return false if @organization.users.count == 1

    @user = @organization.users.find_by(uid: github_user_id)

    return true unless @user

    transfer_assignments if user_owns_any_assignments?
    @organization.users.delete(@user)
  end
  # rubocop:enable Metrics/AbcSize

  def user_owns_any_assignments?
    user_owns_assignments? || user_owns_group_assignments?
  end

  def user_owns_assignments?
    @organization.assignments.where(creator_id: @user.id).any?
  end

  def user_owns_group_assignments?
    @organization.group_assignments.where(creator_id: @user.id).any?
  end

  def transfer_assignments
    new_owner = @organization.users.where.not(id: @user.id).first
    all_assignments_of_user = @organization.all_assignments.select { |assignment| assignment.creator_id == @user.id }
    all_assignments_of_user.map do |assignment|
      assignment.update(creator_id: new_owner.id)
    end
  end
end
