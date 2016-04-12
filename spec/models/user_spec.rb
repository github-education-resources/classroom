require 'rails_helper'

RSpec.describe User, type: :model do
  let(:github_omniauth_hash) { OmniAuth.config.mock_auth[:github] }
  let(:user)                 { create(:user) }

  describe '#access_token' do
    it 'is an alias for #token' do
      expect(user.access_token).to eql(user.token)
    end
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

  describe '#flipper_id' do
    it 'should return an id' do
      expect(user.flipper_id).to eq("User:#{user.id}")
    end
  end

  describe '#github_user' do
    it 'has an instance of GitHubUser' do
      expect(user.github_user).to be_instance_of(GitHubUser)
    end
  end

  describe '#staff?' do
    it 'returns if the User is a site_admin' do
      expect(user.staff?).to be(false)

      user.update_attributes(site_admin: true)
      expect(user.staff?).to be(true)
    end
  end
end
