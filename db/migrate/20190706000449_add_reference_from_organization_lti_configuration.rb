class AddReferenceFromOrganizationLtiConfiguration < ActiveRecord::Migration[5.1]
  def change
    change_table :organizations do |t|
      t.belongs_to :lti_configuration
    end
  end
end
