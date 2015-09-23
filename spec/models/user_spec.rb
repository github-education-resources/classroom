require 'rails_helper'

RSpec.describe User, type: :model do
  let(:github_omniauth_hash) { OmniAuth.config.mock_auth[:github] }
  let(:user)                 { create(:user) }

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

  describe '#staff?' do
    it 'returns if the User is a site_admin' do
      expect(user.staff?).to be(false)

      user.site_admin = true
      user.save!

      expect(user.staff?).to be(true)
    end
  end

  describe '#valid_auth_token?', :vcr do
    it 'returns false if the token is not good' do
      expect(user.valid_auth_token?).to be(false)
    end

    it 'returns true is the token is good' do
      user = GitHubFactory.create_owner_classroom_org.users.first
      expect(user.valid_auth_token?).to be(true)
    end
  end
end
