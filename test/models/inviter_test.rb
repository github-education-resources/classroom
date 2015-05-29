require 'test_helper'

class InviterTest < ActiveSupport::TestCase
  def setup
    @user         = users(:tobias)
    @organization = @user.organizations.first
  end

  test '#create_invitation with an existing team returns a valid invitation' do

  end

  test '#create_invitation with new team parameters returns a valid invitation' do

  end
end
