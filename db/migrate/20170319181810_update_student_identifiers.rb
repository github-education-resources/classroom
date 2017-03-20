# frozen_string_literal: true
class UpdateStudentIdentifiers < ActiveRecord::Migration[5.0]
  def change
    remove_column :student_identifier_types, :content_type, :integer

    add_index :student_identifiers, [:organization_id, :user_id, :student_identifier_type_id],
              unique: true,
              name: 'index_student_identifiers_on_org_and_user_and_type'
  end
end
