require 'rails_helper'

RSpec.describe User, type: :model do
  let(:github_omniauth_hash) { OmniAuth.config.mock_auth[:github] }
  let(:user)                 { create(:user) }

  it { should have_many(:repo_accesses).dependent(:destroy) }
  it { should have_many(:groups).through(:repo_accesses)    }

  it { should have_and_belong_to_many(:organizations) }

  it { should validate_presence_of(:uid)   }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:uid) }

  it { should validate_presence_of(:token)   }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:token) }

  describe '#assign_from_auth_hash' do
    it 'updates the users attributes' do
      user.assign_from_auth_hash(github_omniauth_hash)
      expect(github_omniauth_hash.credentials.token).to eq(user.token)
    end
  end

  describe '#create_from_auth_hash' do
    it 'creates a valid user' do
      expect { User.create_from_auth_hash(github_omniauth_hash) }.to change { User.count }
    end
  end

  describe '#find_by_auth_hash' do
    it 'finds the correct user' do
      User.create_from_auth_hash(github_omniauth_hash)
      located_user = User.find_by_auth_hash(github_omniauth_hash)

      expect(located_user).to eq(User.last)
    end
  end

  describe '#github_client' do
    it 'sets or creates a new GitHubClient with the users token' do
      expect(user.github_client.class).to eql(Octokit::Client)
    end
  end

  describe '#github_login', :vcr do
    it 'gets the users GitHub login' do
      user.token   = classroom_owner_github_token
      github_login = user.github_login

      assert_requested :get, github_url('/user')
      expect(github_login).to eq('tarebyte')
    end
  end
end
