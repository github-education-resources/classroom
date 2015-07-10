require 'rails_helper'

RSpec.describe GroupAssignmentRepo, type: :model do
  it { should belong_to(:group_assignment)  }
  it { should have_many(:repo_accesses) }

  it { should validate_presence_of(:github_repo_id) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:github_repo_id) }

  it { should validate_presence_of(:group_assignment) }

  it { should validate_presence_of(:group)                                }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:group).scoped_to(:group_assignment) }
end
