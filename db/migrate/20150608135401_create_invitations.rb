class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :individual_assignment_invitations do |t|
      t.string :key,                       null: false
      t.belongs_to :individual_assignment
    end

    add_index :individual_assignment_invitations, :key, unique: true, name: 'indv_assg_invitation_key'

    create_table :group_assignment_invitations do |t|
      t.string :key,                       null: false
      t.belongs_to :group_assignment
    end

    add_index :group_assignment_invitations, :key, unique: true, name: 'group_assg_invitation_key'
  end
end
