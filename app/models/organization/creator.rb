# frozen_string_literal: true

class Organization
  class Creator
    include Rails.application.routes.url_helpers

    attr_reader :users, :github_id

    class Result
      class Error < StandardError; end

      def self.success(organization)
        new(:success, organization: organization)
      end

      def self.failed(error)
        new(:failed, error: error)
      end

      attr_reader :error, :organization

      def initialize(status, organization: nil, error: nil)
        @status       = status
        @organization = organization
        @error        = error
      end

      def success?
        @status == :success
      end

      def failed?
        @status == :failed
      end
    end

    NO_ADMIN_ORG_TOKEN_ERROR = "No user has the `admin:org_hook` scope on their token."

    attr_reader :users

    # Public: Create an Organization.
    #
    # users     - An Array of Users that will own the organization.
    # github_id - The Integer GitHub id.
    #
    # Examples
    #
    #   Organization::Creator.perform([User.first], github_id: 12345)
    #
    # Returns an Organization::Creator::Result.
    def self.perform(users:, github_id:)
      new(users: users, github_id: github_id).perform
    end

    def initialize(users:, github_id:)
      @users     = users
      @github_id = github_id.to_i
    end

    # Internal: Create create a Classroom from an Organization.
    #
    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    def perform
      organization = Organization.new

      ensure_users_are_authorized!

      begin
        github_organization = GitHubOrganization.new(users.first.github_client, github_id)
        organization_webhook = ensure_organization_webhook_exists!

        organization.update_attributes!(
          github_id: github_id,
          title: title,
          users: users,
          github_global_relay_id: github_organization.node_id,
          organization_webhook: organization_webhook
        )
      rescue ActiveRecord::RecordInvalid => err
        raise Result::Error, err.message
      end

      update_default_repository_permission_to_none!(organization)

      GitHubClassroom.statsd.increment("classroom.created")

      Result.success(organization)
    rescue Result::Error => err
      destroy_organization(organization)

      Result.failed(err.message)
    end
    # rubocop:enable AbcSize
    # rubocop:enable MethodLength

    private

    # Internal: Creates a OrganizationWebhook if one does not exist yet,
    # then creates an GitHubOrgHook if one does not exist, or activates the GitHubOrgHook if it is inactive.
    #
    # Returns the OrganizationWebhook, or raises an Result::Error
    def ensure_organization_webhook_exists!
      client = user_with_admin_org_hook_scope&.github_client
      raise Result::Error, NO_ADMIN_ORG_TOKEN_ERROR if client.nil?

      organization_webhook = OrganizationWebhook.find_or_initialize_by(github_organization_id: github_id)
      organization_webhook.ensure_webhook_is_active!(client: client)
      organization_webhook
    rescue ActiveRecord::RecordInvalid, GitHub::Error => error
      raise Result::Error, error.message
    end

    # Internal: Make sure every user being added to the
    # Organization is an admin on GitHub.
    #
    # Returns nil or raises a Result::Error
    def ensure_users_are_authorized!
      raise Result::Error, "Cannot create an organization with no users" if users.empty?

      users.each do |user|
        login = user.github_user.login(use_cache: false)
        next if GitHubOrganization.new(user.github_client, github_id).admin?(login)
        raise Result::Error, "@#{login} is not a GitHub admin for this Organization."
      end
    end

    # Internal: Set the default repository permission so that students
    # don't accidently see other repos.
    #
    # Returns nil or raises a Result::Error
    def update_default_repository_permission_to_none!(organization)
      organization.github_organization.update_default_repository_permission!("none")
    rescue GitHub::Error => err
      raise Result::Error, err.message
    end

    # Internal: Remove the Organization from the database.
    #
    # Returns true or raises an ActiveRecord::Error.
    def destroy_organization(organization)
      organization.destroy!
    end

    # Internal: Get the default title for the Organization.
    #
    # Example
    #
    #  title
    #  # => 'tatooine-moisture-farmers'
    #
    # Returns the String title.
    def title
      return "" if users.empty?

      github_client = users.sample.github_client
      github_org = GitHubOrganization.new(github_client, github_id)

      org_identifier = github_org.name.presence || github_org.login

      find_unique_title(org_identifier)
    end

    # Internal: Find User that has the `admin:org_hook` scope
    # for creating the organization webhook.
    #
    # Examples
    #
    #   user_with_admin_org_hook_scope
    #   # => #<User:0x007fd7f0320a30
    #      id: 1,
    #      uid: 564113,
    #      token: "8675309",
    #      created_at: Sun, 20 Nov 2016 16:29:43 UTC +00:00,
    #      updated_at: Tue, 22 Nov 2016 03:46:10 UTC +00:00,
    #      site_admin: true,
    #      last_active_at: Fri, 25 Nov 2016 03:39:54 UTC +00:00>
    #
    # Returns a User or nil if one could not be found.
    def user_with_admin_org_hook_scope
      return @users_with_scope.sample if defined?(@users_with_scope)

      @users_with_scope = []

      users.each do |user|
        next unless user.github_client_scopes.include?("admin:org_hook")
        @users_with_scope << user
      end

      @users_with_scope.sample
    end

    # Internal: Generates unique name for classroom if default
    # name has already been taken
    #
    # Returns a String with an unique title
    def find_unique_title(identifier)
      # First Classroom on Org will have postfix 1
      base_title = "#{identifier}-classroom-1"

      count = 1
      until unique_title?(base_title)
        # Increments count at end of title
        base_title = base_title.gsub(/\-\d+$/, "") + "-#{count}"
        count += 1
      end

      base_title
    end

    # Internal: Checks if a classroom with the same title and github_id
    # exists already
    #
    # Returns a Boolean on whether duplicate classroom title is
    def unique_title?(base_title)
      Organization.where(title: base_title, github_id: github_id).blank?
    end
  end
end
