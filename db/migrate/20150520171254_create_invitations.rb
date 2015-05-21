class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.string  :title,      null: false
      t.integer :team_id,    null: false
      t.string  :key,        null: false

      t.belongs_to :organizations, index: true

      t.timestamps null: false
    end

    add_index :invitations, [:team_id], unique: true
    add_index :invitations, [:key], unique: true
  end
end
