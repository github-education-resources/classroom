class SoftDelete < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :deleted_at, :datetime
    add_index  :organizations, :deleted_at

    add_column :assignments, :deleted_at, :datetime
    add_index  :assignments, :deleted_at

    add_column :assignment_invitations, :deleted_at, :datetime
    add_index  :assignment_invitations, :deleted_at

    add_column :group_assignments, :deleted_at, :datetime
    add_index  :group_assignments, :deleted_at

    add_column :group_assignment_invitations, :deleted_at, :datetime
    add_index  :group_assignment_invitations, :deleted_at
  end
end
