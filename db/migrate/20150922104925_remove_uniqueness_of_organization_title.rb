class RemoveUniquenessOfOrganizationTitle < ActiveRecord::Migration
  def change
    remove_index :organizations, column: :title
  end
end
