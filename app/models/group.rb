class Group < ActiveRecord::Base
  has_many :repo_access

  belongs_to :grouping
end
