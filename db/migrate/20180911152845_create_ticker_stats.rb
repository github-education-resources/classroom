class CreateTickerStats < ActiveRecord::Migration[5.1]
  def change
    create_table :ticker_stats do |t|
      t.integer :user_count
      t.integer :repo_count

      t.timestamps
    end
  end
end
