class CreateDeadlinesTable < ActiveRecord::Migration[5.0]
  def change
    create_table :deadlines do |t|
      t.references :assignment, polymorphic: true
      t.datetime :deadline_at, null: false

      t.timestamps
    end
  end
end
