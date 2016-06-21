class AddSlugToGroupingsAndGroups < ActiveRecord::Migration
  def change
    add_column :groupings, :slug, :string
    add_column :groups,    :slug, :string
  end
end
