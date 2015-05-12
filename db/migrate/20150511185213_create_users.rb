class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider,    null: false
      t.string :uid,         null: false
      t.string :nickname,    null: false
      t.string :email
      t.string :name
      t.string :token,       null: false

      t.timestamps null: false
    end
  end
end
