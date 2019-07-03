class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :uid,         null: false
      t.string :token,       null: false

      t.timestamps null: false
    end

    add_index :users, :uid,   unique: true
    add_index :users, :token, unique: true
  end
end
