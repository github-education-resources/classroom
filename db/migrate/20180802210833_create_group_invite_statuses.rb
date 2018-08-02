class CreateGroupInviteStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :group_invite_statuses do |t|
      t.integer :status, default: 0
      t.belongs_to :group, foreign_key: true
      t.belongs_to :group_assignment_invitation, foreign_key: true

      t.timestamps
    end
  end
end
