class CreateStudentIdentifiers < ActiveRecord::Migration
  def change

    create_table :student_identifier_types do |t|
      t.belongs_to :organization, index: true
      t.string :name
      t.string :description
      t.integer :content_type
    end

    create_table :student_identifiers do |t|
      t.belongs_to :organization, index: true
      t.belongs_to :user,         index: true
      t.belongs_to :student_identifier_type
      t.string :value
    end

    add_column :assignments, :student_identifier_type_id, :integer, null: false, default: 0
  end
end
