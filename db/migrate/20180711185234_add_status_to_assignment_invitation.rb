class AddStatusToAssignmentInvitation < ActiveRecord::Migration[5.1]
  def change
    add_column :assignment_invitations, :status, :integer
  end
end
