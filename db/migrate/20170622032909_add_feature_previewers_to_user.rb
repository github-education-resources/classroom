class AddFeaturePreviewersToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :feature_previewer, :boolean, default: false
  end
end
