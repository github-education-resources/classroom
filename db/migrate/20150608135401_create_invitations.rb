class CreateInvitations < ActiveRecord::Migration[4.2]
  def change
    create_table :assignment_invitations do |t|
      t.string :key,            null: false
      t.belongs_to :assignment, index: true

      t.timestamps null: false
    end

    add_index :assignment_invitations, :key, unique: true

    create_table :group_assignment_invitations do |t|
      t.string     :key,              null: false
      t.belongs_to :group_assignment, index: true

      t.timestamps null: false
    end

    add_index :group_assignment_invitations, :key, unique: true
  end
end
