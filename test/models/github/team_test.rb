require 'test_helper'

class Github::TeamTest < ActiveSupport::TestCase
  def setup
    user         = users(:tobias)
    organization = user.organizations.first
    @github_team = Github::Team.new(user.github_client, organization.github_id)
  end

  test '#find_or_create_team returns an existing team' do

  end

  test '#find_or_create_team returns a new team' do

  end

  test '#find_or_create_team returns a Github::Null::Team object if there was an error' do

  end
end
