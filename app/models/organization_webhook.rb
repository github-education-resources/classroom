# frozen_string_literal: true

class OrganizationWebhook < ApplicationRecord
  class NoValidTokenError < StandardError; end

  has_many :organizations
  has_many :users, through: :organizations

  validates :github_id, uniqueness: true, allow_nil: true

  validates :github_organization_id, presence:   true
  validates :github_organization_id, uniqueness: true

  # External: Finds a User's token that has the `admin:org_hook` scope
  # for creating the organization webhook.
  #
  # Example:
  #
  #   admin_org_hook_scoped_github_client
  #   # => {token_string}
  #
  # Returns a User's token or raises a NoValidTokenError if one could not be found.
  #
  # Warning: This could potentially take very long for organizations
  # of a large size, so invoke cautiously.
  def admin_org_hook_scoped_github_client
    token = if Rails.env.test?
              users.first&.token
            else
              users_with_admin_org_hook_scope.sample&.token
            end
    raise NoValidTokenError, "No valid token with the `admin:org` hook scope." if token.nil?
    Octokit::Client.new(access_token: token)
  end

  # External: Creates an organization webhook, and saves it's ID.
  #
  # client - the client that used to create the organization webhook
  #          (Note: client must have the `admin:org_hook` scope).
  #
  # Returns true if successful, otherwise raises a GitHub::Error or ActiveRecord::RecordInvalid.
  def create_org_hook!(client:)
    github_organization = GitHubOrganization.new(client, github_organization_id)
    github_id = github_organization.create_organization_webhook(config: { url: webhook_url }).id
    save!
  rescue ActiveRecord::RecordInvalid => err
    github_organization.remove_organization_webhook(github_id)
    raise err
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
  # Returns a list of Users with the `admin:org` scope token
  # or an empty list if none could be found.
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

  # Internal: Get the proper webhook url.
  #
  # Rails.env.production?
  # # => true
  #
  # webhook_url
  # # => "https://classroom.github.com"
  #
  # Returns a String for the url or raises an error.
  def webhook_url
    webhook_url_prefix = ENV["CLASSROOM_WEBHOOK_URL_PREFIX"]

    error_message = if Rails.env.production?
                      "WebHook failed to be created, please open an issue at https://github.com/education/classroom/issues/new" # rubocop:disable Metrics/LineLength
                    else
                      "CLASSROOM_WEBHOOK_URL_PREFIX is not set, please check your .env file"
                    end

    raise error_message if webhook_url_prefix.blank?
    hooks_path = Rails.application.routes.url_helpers.github_hooks_path
    "#{webhook_url_prefix}#{hooks_path}"
  end
end
