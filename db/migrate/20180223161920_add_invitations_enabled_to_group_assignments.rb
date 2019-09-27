class AddInvitationsEnabledToGroupAssignments < ActiveRecord::Migration[5.1]
  def change
    add_column :group_assignments, :invitations_enabled, :boolean, default: true
  end
end
