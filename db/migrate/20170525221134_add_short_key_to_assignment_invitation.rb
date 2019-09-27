class AddShortKeyToAssignmentInvitation < ActiveRecord::Migration[5.0]
  def change
    add_column :assignment_invitations, :short_key, :string
    add_column :group_assignment_invitations, :short_key, :string

    add_index :assignment_invitations,       :short_key
    add_index :group_assignment_invitations, :short_key
  end
end
