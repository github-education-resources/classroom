class CreateCloudIdes < ActiveRecord::Migration[5.2]
  def change
    create_table :cloud_ides do |t|
      t.string :title, null: false
      t.string :description, null: false
      t.string :homepage, null: false
      t.timestamps
    end
  end
end
