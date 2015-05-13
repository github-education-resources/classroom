class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string  :login,      null: false
      t.integer :github_id,  null: false

      t.timestamps null: false
    end

    add_index :organizations, [:login],     unique: true
    add_index :organizations, [:github_id], unique: true

    create_table :organizations_users, id: false do |t|
      t.belongs_to :user,         index: true
      t.belongs_to :organization, index: true
    end
  end
end
