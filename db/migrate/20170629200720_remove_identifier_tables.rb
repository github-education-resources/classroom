class RemoveIdentifierTables < ActiveRecord::Migration[5.1]
  def change
    remove_column :assignments, :student_identifier_type_id
    remove_column :group_assignments, :student_identifier_type_id

    drop_table :student_identifier_types
    drop_table :student_identifiers
  end
end
