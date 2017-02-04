class CreateStudentIdentifiers < ActiveRecord::Migration[4.2]
  def change
    create_table :student_identifier_types do |t|
      t.belongs_to :organization, index: true
      t.string :name,          null: false
      t.string :description,   null: false
      t.integer :content_type, null: false
      t.datetime :created_at,  null: false
      t.datetime :updated_at,  null: false
      t.datetime :deleted_at
    end

    create_table :student_identifiers do |t|
      t.belongs_to :organization, index: true
      t.belongs_to :user,         index: true
      t.belongs_to :student_identifier_type
      t.string :value,        null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.datetime :deleted_at
    end

    add_column :assignments, :student_identifier_type_id, :integer
    add_column :group_assignments, :student_identifier_type_id, :integer

    add_index :student_identifiers, :student_identifier_type_id
  end
end
