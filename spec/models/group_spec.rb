require 'rails_helper'

RSpec.describe Group, type: :model do
  it { should belong_to(:grouping) }

  it { should have_and_belong_to_many(:repo_accesses) }

  it { should validate_presence_of(:github_team_id) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { validate_uniqueness_of(:github_team_id) }

  it { should validate_presence_of(:grouping) }

  it { should validate_presence_of(:title) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { validate_uniqueness_of(:title) }
end
