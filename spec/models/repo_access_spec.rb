require 'rails_helper'

RSpec.describe RepoAccess, type: :model do
  it { should belong_to(:user)         }
  it { should belong_to(:organization) }

  it { should have_and_belong_to_many(:groups) }

  it { should validate_presence_of(:github_team_id)     }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:github_team_id) }

  it { should validate_presence_of(:organization) }

  it { should validate_presence_of(:user) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:github_team_id).scoped_to(:organization) }
end
