# frozen_string_literal: true

class OrganizationWebhook < ApplicationRecord
  has_many :organizations
  has_many :users, through: :organizations

  validates :github_id, uniqueness: true, allow_nil: true

  validates :github_organization_id, presence:   true
  validates :github_organization_id, uniqueness: true

  def admin_org_hook_scope_github_client
    if Rails.env.test?
      token = users.first.token unless users.first.nil?
    else
      token = user_with_admin_org_hook_scope.sample
    end
    Octokit::Client.new(access_token: token)
  end

  private

  # Internal: Find Users that has the `admin:org_hook` scope
  # for creating the organization webhook.
  #
  # Example:
  #
  #   users_with_admin_org_hook_scope
  #   # => [#<User:0x007fd7f0320a30
  #      id: 1,
  #      uid: 564113,
  #      token: "8675309",
  #      created_at: Sun, 20 Nov 2016 16:29:43 UTC +00:00,
  #      updated_at: Tue, 22 Nov 2016 03:46:10 UTC +00:00,
  #      site_admin: true,
  #      last_active_at: Fri, 25 Nov 2016 03:39:54 UTC +00:00>]
  #
  # Returns a User or nil if one could not be found.
  #
  # Warning: This could potentially take very long for organizations
  # of a large size, so invoke cautiously.
  def users_with_admin_org_hook_scope
    return @users_with_scope if defined?(@users_with_scope)

    @users_with_scope = []

    users.find_in_batches(batch_size: 100) do |users|
      users.each do |user|
        next unless user.github_client_scopes.include?("admin:org_hook")
        @users_with_scope << user
      end
    end

    @users_with_scope
  end
end
