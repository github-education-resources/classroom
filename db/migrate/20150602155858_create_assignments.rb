class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.string     :title, null: false
      t.belongs_to :organization, index: true

      t.timestamps null: false
    end
  end
end
