class NullAssignmentInvitation < AssignmentInvitation
  def to_partial_path
    'individual_assignment_invitations/null'
  end

  protected

  def assign_key
    nil
  end
end
