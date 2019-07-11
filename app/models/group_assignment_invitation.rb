# frozen_string_literal: true

class GroupAssignmentInvitation < ApplicationRecord
  include ShortKey
  include StafftoolsSearchable

  define_pg_search(columns: %i[id key])

  default_scope { where(deleted_at: nil) }

  belongs_to :group_assignment

  has_one :grouping,     through: :group_assignment
  has_one :organization, through: :group_assignment

  has_many :groups, through: :grouping
  has_many :group_invite_statuses, dependent: :destroy

  validates :group_assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  validates :short_key, uniqueness: true, allow_nil: true

  after_initialize :assign_key

  delegate :title, to: :group_assignment

  def redeem_for(invitee, selected_group = nil, new_group_title = nil)
    return Result.failed("Invitations for this assignment have been disabled.") unless enabled?

    repo_access = RepoAccess.find_or_create_by!(user: invitee, organization: organization)
    group_creator_result = group(repo_access, selected_group, new_group_title)
    return Result.failed(group_creator_result.error) if group_creator_result.failed?

    invitees_group = group_creator_result.group
    invitees_group.repo_accesses << repo_access unless invitees_group.repo_accesses.include?(repo_access)

    group_assignment_repo(invitees_group)
  end

  def to_param
    key
  end

  def enabled?
    group_assignment.invitations_enabled?
  end

  def status(group)
    group_invite_status = group_invite_statuses.find_by(group: group)
    return group_invite_status if group_invite_status.present?

    GroupInviteStatus.create(group: group, group_assignment_invitation: self)
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end

  private

  def group(repo_access, selected_group, selected_group_title)
    group = Group.joins(:repo_accesses).find_by(grouping: grouping, repo_accesses: { id: repo_access.id })

    return Group::Creator::Result.success(group) if group.present?
    return Group::Creator::Result.success(selected_group) if selected_group

    Group::Creator.perform(title: selected_group_title, grouping: grouping)
  end

  def group_assignment_repo(invitees_group)
    group_assignment_params = { group_assignment: group_assignment, group: invitees_group }
    repo                    = GroupAssignmentRepo.find_by(group_assignment_params)
    invite_status           = status(invitees_group)

    invite_status.accepted! if invite_status.unaccepted?
    if repo
      Result.success(repo)
    else
      Result.pending
    end
  end
end
