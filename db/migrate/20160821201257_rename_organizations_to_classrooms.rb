class RenameOrganizationsToClassrooms < ActiveRecord::Migration
  def change
    rename_table :organizations, :classrooms

    rename_table :organizations_users, :classrooms_users

    rename_column :assignments,              :organization_id, :classroom_id
    rename_column :classrooms_users,         :organization_id, :classroom_id
    rename_column :group_assignments,        :organization_id, :classroom_id
    rename_column :groupings,                :organization_id, :classroom_id
    rename_column :repo_accesses,            :organization_id, :classroom_id
    rename_column :student_identifier_types, :organization_id, :classroom_id
    rename_column :student_identifiers,      :organization_id, :classroom_id

    rename_column :classrooms, :github_id, :github_organization_id
  end
end
