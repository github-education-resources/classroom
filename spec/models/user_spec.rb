# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  let(:github_omniauth_hash) { OmniAuth.config.mock_auth[:github] }
  let(:user)                 { create(:user) }

  describe '#assign_from_auth_hash', :vcr do
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
      located_user = User.find_by_auth_hash(github_omniauth_hash) # rubocop:disable Rails/DynamicFindBy

      expect(located_user).to eq(User.last)
    end
  end

  describe '#flipper_id' do
    it 'should return an id' do
      expect(user.flipper_id).to eq("User:#{user.id}")
    end
  end

  describe '#github_client' do
    it 'sets or creates a new GitHubClient with the users token' do
      expect(user.github_client.class).to eql(Octokit::Client)
    end
  end

  describe '#github_user' do
    it 'sets or creates a new GitHubUser with the users uid' do
      expect(user.github_user.class).to eql(GitHubUser)
      expect(user.github_user.id).to eql(user.uid)
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

  describe '#github_client_scopes', :vcr do
    it 'returns an Array of scopes' do
      user.assign_from_auth_hash(github_omniauth_hash)
      expect(user.github_client_scopes).to eq(%w(admin:org delete_repo repo user:email))
    end
  end

  describe 'tokens', :vcr do
    it 'does not allow a User to lose their token scope' do
      student = GitHubFactory.create_classroom_student

      good_token = student.token
      bad_token  = 'e72e16c7e42f292c6912e7710c838347ae178b4a'

      student.update_attributes(token: bad_token)

      expect(student.token).to eql(good_token)
    end
  end
end
