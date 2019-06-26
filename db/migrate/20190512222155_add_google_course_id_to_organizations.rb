class AddGoogleCourseIdToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :google_course_id, :string
    add_index  :organizations, :google_course_id
  end
end
