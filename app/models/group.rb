class Group < ActiveRecord::Base
  belongs_to :grouping
  has_many   :repo_access
end
