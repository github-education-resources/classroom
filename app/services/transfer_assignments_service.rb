# frozen_string_literal: true

class TransferAssignmentsService
  attr_accessor :organization, :old_user, :new_user

  def initialize(organization, old_user, new_user = nil)
    @organization = organization
    @old_user = old_user
    @new_user = new_user || @organization.users.where.not(id: old_user.id).first
  end

  def transfer
    return false unless user_owns_any_assignments?
    organization.all_assignments.each do |assignment|
      next unless assignment.creator_id == old_user.id
      assignment.update(creator_id: new_user.id)
    end
  end

  private

  def user_owns_any_assignments?
    user_owns_assignments? || user_owns_group_assignments?
  end

  def user_owns_assignments?
    organization.assignments.where(creator_id: old_user.id).any?
  end

  def user_owns_group_assignments?
    organization.group_assignments.where(creator_id: old_user.id).any?
  end
end
