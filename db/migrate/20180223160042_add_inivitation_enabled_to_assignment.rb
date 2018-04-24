class AddInivitationEnabledToAssignment < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :invitations_enabled, :boolean, default: true
  end
end
