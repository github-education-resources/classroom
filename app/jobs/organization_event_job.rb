# frozen_string_literal: true

# Documentation: https://developer.github.com/v3/activity/events/types/#organizationevent
class OrganizationEventJob < ApplicationJob
  queue_as :github_event

  def perform(payload_body)
    return true unless payload_body.dig("action") == "member_removed"

    github_user_id = payload_body.dig("membership", "user", "id")
    github_organization_id = payload_body.dig("organization", "id")
    organization = Organization.find_by(github_id: github_organization_id)
    user = organization.users.find_by(uid: github_user_id)

    return true unless user

    transfer_assigments(user, organization) if organization.all_assignments
    organization.users.delete(user)
  end

  def transfer_assigments(user, organization)
    puts "==========TRANSFER============="
    other_owner = organization.users.where.not(id: user.id).first
    puts "other_owner is : #{other_owner.inspect}"
    organization.all_assignments.map do |a|
      puts "Creator id is: #{a.creator_id}"
      puts "New creator id is: #{other_owner.id}"
      a.creator_id = other_owner.id if a.creator_id == user.id
    end
    puts "==============================="
    puts organization.all_assignments.inspect
    puts "==========TRANSFER============="
  end
end
