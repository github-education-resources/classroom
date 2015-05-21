class AddStudentsTeamToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :students_team_id, :integer
  end
end
