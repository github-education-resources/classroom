class AddSiteAdminToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :site_admin, :boolean, default: false
  end
end
