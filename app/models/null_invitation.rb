class NullInvitation < Invitation
  def to_partial_path
    'invitations/null'
  end

  protected

  def assign_key
    nil
  end
end
