# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @subject              = users(:teacher)
    @other_user           = users(:student)
    @github_omniauth_hash = OmniAuth.config.mock_auth[:github]

    @invalid_token = 'e72e16c7e42f292c6912e7710c838347ae178b4a'
  end

  test 'requires a uid' do
    @subject.uid = nil
    refute_predicate @subject, :valid?
    assert @subject.errors[:uid].any?
  end

  test 'requires a unique uid' do
    @subject.uid = @other_user.uid
    refute_predicate @subject, :valid?
    assert @subject.errors[:uid].any?
  end

  test 'requires a token' do
    @subject.token = nil
    refute_predicate @subject, :valid?
    assert @subject.errors[:token].any?
  end

  test 'requires a unique token' do
    @subject.token = @other_user.token
    refute_predicate @subject, :valid?
    assert @subject.errors[:token].any?
  end

  test 'requires a last_active_at timestamp' do
    @subject.last_active_at = nil
    refute_predicate @subject, :valid?
    assert @subject.errors[:last_active_at].any?
  end

  test '#authorized_access_token? returns true for a valid GitHub token' do
    @subject.assign_from_auth_hash(@github_omniauth_hash)
    assert_predicate @subject, :authorized_access_token?
  end

  test '#authorized_access_token returns false for a invlaid GitHub token' do
    refute_predicate @subject, :authorized_access_token?
  end

  test '#find_by_auth_hash finds user from an Omniauth hash' do
    user = User.new
    user.assign_from_auth_hash(@github_omniauth_hash)

    assert_equal User.find_by(uid: @github_omniauth_hash[:uid]), user
  end

  test '#flipper_id' do
    assert_equal "User:#{@subject.id}", @subject.flipper_id
  end

  test '#github_client returns an Octokit::Client' do
    github_client = @subject.github_client
    assert_kind_of Octokit::Client, github_client
  end

  test '#github_client returns a Octokit::Client with the proper token' do
    github_client = @subject.github_client
    assert_equal github_client.access_token, @subject.token
  end

  test '#github_client_scopes returns an Array of GitHub token scopes' do
    @subject.assign_from_auth_hash(@github_omniauth_hash)
    scopes = @subject.github_client_scopes

    assert_kind_of Array, scopes

    %w[admin:org admin:org_hook delete_repo repo user:email].each do |scopet|
      assert_includes scopes, scopet
    end
  end

  test '#github_user returns the correct GitHubUser' do
    github_user = @subject.github_user

    assert_kind_of GitHubUser, github_user
    assert_equal github_user.id, @subject.uid
  end

  test "#staff? returns true for site admin's" do
    staff_member = users(:githubber)

    assert_predicate staff_member, :site_admin
    assert_predicate staff_member, :staff?
  end

  test '#staff? returns false for everyone else' do
    refute_predicate @subject, :site_admin
    refute_predicate @subject, :staff?
  end

  test 'token scope cannot be downgraded' do
    @subject.assign_from_auth_hash(@github_omniauth_hash)
    good_token = @subject.token

    @subject.update_attributes(token: @invalid_token)
    assert_equal good_token, @subject.token
  end
end
