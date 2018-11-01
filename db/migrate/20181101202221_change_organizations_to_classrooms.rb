class ChangeOrganizationsToClassrooms < ActiveRecord::Migration[5.1]
  def change
    rename_table :organizations, :classrooms
    rename_table :organizations_users, :classrooms_users

    # assignments
    rename_column :assignments, :organization_id, :classroom_id

    # group_assignments
    rename_column :group_assignments, :organization_id, :classroom_id

    # groupings
    rename_column :groupings, :organization_id, :classroom_id

    # classrooms_users
    rename_column :classrooms_users, :organization_id, :classroom_id

    # repo_accesses
    rename_column :repo_accesses, :organization_id, :classroom_id
  end
end
