class RepoAccessesAndGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :groups_repo_accesses, id: false do |t|
      t.belongs_to :group,       index: true
      t.belongs_to :repo_access, index: true
    end
  end
end
