class AddCachedFieldsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :github_login, :string
    add_column :users, :github_name, :string
    add_column :users, :github_avatar_url, :string
    add_column :users, :github_html_url, :string
  end
end
