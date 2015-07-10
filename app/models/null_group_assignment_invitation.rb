class NullGroupAssignmentInvitation < GroupAssignmentInvitation
  def to_partial_path
    'group_assignment_invitations/null'
  end

  protected

  def assign_key
    nil
  end
end
