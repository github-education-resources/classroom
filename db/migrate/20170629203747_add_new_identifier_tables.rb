class AddNewIdentifierTables < ActiveRecord::Migration[5.1]
  def change
    create_table :rosters do |t|
      t.string :identifier_name, null: false

      t.timestamps null: false
    end

    create_table :roster_entries do |t|
      t.string :identifier, null: false
      t.references :roster, null: false
      t.references :user

      t.timestamps null: false
    end

    add_column :organizations, :roster_id, :integer
    add_index :organizations, :roster_id
  end
end
