class GroupAssignmentInvitation < ActiveRecord::Base
  default_scope { where(deleted_at: nil) }

  has_one :grouping,     through: :group_assignment
  has_one :organization, through: :group_assignment

  has_many :groups, through: :grouping

  belongs_to :group_assignment

  validates :group_assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  # Public: Redeem invitation for a given User
  #
  # invitee         - The User that is invited
  # selected_group  - The Group they wish to join
  # new_group_title - The title they want to give to their new group
  #
  # Returns the full name of the newly created GitHub repository
  def redeem_for(invitee, selected_group = nil, new_group_title = nil)
    repo_access    = RepoAccess.find_or_create_by!(user: invitee, organization: organization)
    invitees_group = group(repo_access, selected_group, new_group_title)

    invitees_group.repo_accesses << repo_access unless invitees_group.repo_accesses.include?(repo_access)

    group_assignment_repo(invitees_group)
  end

  def title
    group_assignment.title
  end

  # Public: Override the GroupAssignmentInvitation path
  # so that it uses its key instead of the id
  #
  # Returns the key as a String
  def to_param
    key
  end

  protected

  # Internal: Assign a SecureRandom hex 16 key to the
  # GroupAssignmentInvitation if it is not already set.
  #
  # Returns the key as a String
  def assign_key
    self.key ||= SecureRandom.hex(16)
  end

  private

  # Internal: Return the appropriate Group for the given RepoAccess
  #
  # If the RepoAccess already belongs to a Group in the GroupAssignments
  # Grouping, then we will return that one. Otherwise we either return the
  # selected Group, or create a new Group depending on what is passed in.
  #
  # This is to ensure that a user cannot be apart of more than one Group
  # in a particular Grouping
  #
  # repo_access     - The RepoAccess
  # selected_group  - An already created Group, that the repo_access may be able to join
  # selected_group_title - A String which has the title parameter for a new Group
  #
  # Example (see redeem_for #20)
  #
  # Returns a Group
  def group(repo_access, selected_group, selected_group_title)
    group = Group.joins(:repo_accesses).find_by(grouping: grouping, repo_accesses: { id: repo_access.id })

    return group if group.present?
    return selected_group if selected_group

    Group.create(title: selected_group_title, grouping: grouping)
  end

  # Internal: Find or create a GroupAssignment for the group
  #
  # invitees_group - A Group which may or may not have a GroupAssignmentRepo
  #
  # Returns the GroupAssignmentRepo
  def group_assignment_repo(invitees_group)
    group_assignment_params = { group_assignment: group_assignment, group: invitees_group }
    repo                    = GroupAssignmentRepo.find_by(group_assignment_params)

    return repo if repo

    GroupAssignmentRepo.create(group_assignment_params)
  end
end
