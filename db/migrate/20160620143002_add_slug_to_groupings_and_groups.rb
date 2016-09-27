class AddSlugToGroupingsAndGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groupings, :slug, :string
    add_column :groups,    :slug, :string
  end
end
