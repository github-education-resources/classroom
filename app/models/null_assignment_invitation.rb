class NullAssignmentInvitation < AssignmentInvitation
  def to_partial_path
    'assignment_invitations/null'
  end

  protected

  def assign_key
    nil
  end
end
