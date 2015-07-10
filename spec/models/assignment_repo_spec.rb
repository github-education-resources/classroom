require 'rails_helper'

RSpec.describe AssignmentRepo, type: :model do
  it { should belong_to(:assignment)  }
  it { should belong_to(:repo_access) }

  it { should validate_presence_of(:assignment) }

  it { should validate_presence_of(:github_repo_id) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:github_repo_id) }

  it { should validate_presence_of(:repo_access) }
end
