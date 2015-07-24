require 'rails_helper'

RSpec.describe User, type: :model do
  let(:github_omniauth_hash) { OmniAuth.config.mock_auth[:github] }
  let(:user)                 { create(:user) }

  it { is_expected.to have_many(:repo_accesses).dependent(:destroy) }

  it { is_expected.to have_and_belong_to_many(:organizations) }

  describe 'validation and uniqueness' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:uid)   }
    it { is_expected.to validate_presence_of(:token) }

    it { is_expected.to validate_uniqueness_of(:uid)   }
    it { is_expected.to validate_uniqueness_of(:token) }
  end

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

  describe '#staff?' do
    it 'returns if the User is a site_admin' do
      expect(user.staff?).to be(false)

      user.site_admin = true
      user.save!

      expect(user.staff?).to be(true)
    end
  end
end
