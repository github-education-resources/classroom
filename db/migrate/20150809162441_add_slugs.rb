class AddSlugs < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :slug, :string, null: false
    add_index  :organizations, :slug

    add_column :assignments, :slug, :string, null: false
    add_index  :assignments, :slug

    add_column :group_assignments, :slug, :string, null: false
    add_index  :group_assignments, :slug
  end
end
