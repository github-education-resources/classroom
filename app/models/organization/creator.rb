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
        organization.update_attributes!(
          github_id: github_id,
          title: title,
          users: users,
          webhook_id: create_organization_webhook!
        )
      rescue ActiveRecord::RecordInvalid => err
        raise Result::Error, err.message
      end

      update_default_repository_permission_to_none!(organization)

      GitHubClassroom.statsd.increment("classroom.created")

      Result.success(organization)
    rescue Result::Error => err
      silently_destroy_organization_webhook(organization)
      destroy_organization(organization)

      Result.failed(err.message)
    end
    # rubocop:enable AbcSize
    # rubocop:enable MethodLength

    private

    # Internal: Create an GitHub Organization WebHook if there
    # is a user who has the correct token scope.
    #
    # Returns an Integer id, or raises a Result::Error
    def create_organization_webhook!
      return unless (user = user_with_admin_org_hook_scope)

      begin
        github_organization = GitHubOrganization.new(user.github_client, github_id)
        webhook = github_organization.create_organization_webhook(config: { url: webhook_url })

        return webhook.id if webhook.try(:id).present?
        raise GitHub::Error
      rescue GitHub::Error
        raise Result::Error, "Could not create WebHook, please try again."
      end
    end

    # Internal: Make sure every user being added to the
    # Organization is an admin on GitHub.
    #
    # Returns nil or raises a Result::Error
    def ensure_users_are_authorized!
      users.each do |user|
        login = user.github_user.login_no_cache
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

    # Internal: Remove the Organization WebHook is possible.
    #
    # Returns true.
    def silently_destroy_organization_webhook(organization)
      return true if organization.webhook_id.nil?
      return true unless (user = user_with_admin_org_hook_scope)

      github_organization = GitHubOrganization.new(user.github_client, github_id)
      github_organization.remove_organization_webhook(organization.webhook_id)

      true
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
      github_org.name.present? ? github_org.name : github_org.login
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

    # Internal: Get the proper webhook url prefix
    #
    # Rails.env.production?
    # # => true
    #
    # webhook_url
    # # => "https://classroom.github.com"
    #
    # Returns a String for the url or raises a Result::Error
    def webhook_url
      webhook_url_prefix = ENV["CLASSROOM_WEBHOOK_URL_PREFIX"]

      error_message = if Rails.env.production?
                        "WebHook failed to be created, please open an issue at https://github.com/education/classroom/issues/new" # rubocop:disable Metrics/LineLength
                      else
                        "CLASSROOM_WEBHOOK_URL_PREFIX is not set, please check your .env file"
                      end

      hooks_path = Rails.application.routes.url_helpers.github_hooks_path
      return "#{webhook_url_prefix}#{hooks_path}" if webhook_url_prefix.present?

      raise Result::Error, error_message
    end
  end
end
