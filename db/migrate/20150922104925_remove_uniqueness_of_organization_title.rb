class RemoveUniquenessOfOrganizationTitle < ActiveRecord::Migration[4.2]
  def change
    remove_index :organizations, column: :title
  end
end
