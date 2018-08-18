class RemoveStatusFromAssignmentInvitation < ActiveRecord::Migration[5.1]
  def change
    remove_column :assignment_invitations, :status, :integer
  end
end
