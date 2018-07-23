class CreateInviteStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :invite_statuses do |t|
      t.integer :status, default: 0
      t.belongs_to :assignment_invitation, foreign_key: true
      t.belongs_to :user, foreign_key: true

      t.timestamps
    end
  end
end
