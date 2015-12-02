require 'rails_helper'

RSpec.describe Stafftools::GroupAssignmentReposController, type: :controller do
  let(:user)    { GitHubFactory.create_owner_classroom_org.users.first }

  before(:each) do
    sign_in(user)
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
      end
    end

    context 'as an authorized user' do
    end
  end
end
