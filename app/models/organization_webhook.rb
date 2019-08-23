# frozen_string_literal: true

class OrganizationWebhook < ApplicationRecord
  class NoValidTokenError < StandardError; end
  WEBHOOK_URL_PRODUCTION_ERROR = "WebHook failed to be created,"\
    " please open an issue at https://github.com/education/classroom/issues/new"
  WEBHOOK_URL_DEVELOPMENT_ERROR = "CLASSROOM_WEBHOOK_URL_PREFIX is not set,"\
    " please check your .env file."

  has_many :organizations
  has_many :users, through: :organizations

  validates :github_id, uniqueness: true, allow_nil: true

  validates :github_organization_id, presence:   true
  validates :github_organization_id, uniqueness: true

  def github_org_hook(client)
    @github_org_hook ||= GitHubOrgHook.new(
      client,
      github_organization_id,
      github_id,
      headers: GitHub::APIHeaders.no_cache_no_store
    )
  end

  def github_organization(client)
    @github_organization ||= GitHubOrganization.new(client, github_organization_id)
  end

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

    GitHubClassroom.github_client(access_token: token)
  end

  # External: Creates an organization webhook, and saves it's ID.
  #
  # client - The client that used to create the organization webhook
  #          (Note: client must have the `admin:org_hook` scope).
  #
  # Returns true if successful, otherwise raises a GitHub::Error or ActiveRecord::RecordInvalid.
  def create_org_hook!(client)
    self.github_id = github_organization(client).create_organization_webhook(config: { url: webhook_url }).id
    save!
  rescue ActiveRecord::RecordInvalid => err
    github_organization(client).remove_organization_webhook(github_id)
    raise err
  end

  # External: Activates an organization webhook.
  #
  # client - The client that used to edit the organization webhook
  #          (Note: client must have the `admin:org_hook` scope).
  #
  # Returns true if successful, otherwise raises a GitHub::Error.
  def activate_org_hook(client)
    github_organization(client).activate_organization_webhook(github_id, config: { url: webhook_url })
    true
  end

  # External: Checks if an org hook exists and is active,
  # otherwise creates one and saves.
  #
  # client - The client that used to create the organization webhook
  #          (Note: client must have the `admin:org_hook` scope).
  #          If not provided, searches for Users with `admin:org_hook` scoped token.
  #
  # Returns true if successful. Raises a GitHub::Error or ActiveRecord::RecordInvalid if
  # something goes wrong creating the org hook. Raises a NoValidTokenError if no client was passed
  # and no User token with the `admin:org_hook` scope could be found.
  #
  # Warning: If no client argument is passed, this could potentially take very long for organizations
  # of a large size. Invoke cautiously.
  def ensure_webhook_is_active!(client: nil)
    client ||= admin_org_hook_scoped_github_client
    retrieve_org_hook_id!(client) if github_id.blank?
    return create_org_hook!(client) if github_id.blank?
    github_org_hook_is_active = github_org_hook(client).active?
    return create_org_hook!(client) if github_org_hook_is_active.nil?
    return activate_org_hook(client) unless github_org_hook_is_active
    true
  end

  private

  # Internal: Retrieves the classroom webhook id on GitHub if it exists and saves it.
  #
  # This is possible assuming that classroom only creates one webhook in production.
  #
  # Returns the webhook id if the webhook id could be retrieved and saved or nil.
  def retrieve_org_hook_id!(client)
    webhooks = github_organization(client).organization_webhooks
    return nil if webhooks.empty?

    # There should only be one webhook that Classroom creates in production
    self.github_id = webhooks.first.id
    save!
    github_id
  rescue GitHub::Error, ActiveRecord::RecordInvalid
    nil
  end

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
                      WEBHOOK_URL_PRODUCTION_ERROR
                    else
                      WEBHOOK_URL_DEVELOPMENT_ERROR
                    end

    raise error_message if webhook_url_prefix.blank?
    hooks_path = Rails.application.routes.url_helpers.github_hooks_path
    "#{webhook_url_prefix}#{hooks_path}"
  end
end
