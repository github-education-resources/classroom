class AddLtiResourceLinkIdToAssignment < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :lti_resource_link_id, :string
    add_index :assignments, :lti_resource_link_id, unique: true
  end
end
