# frozen_string_literal: true

class OrganizationDefaultRepositoryPermissionMigrator
  attr_reader :organization

  class Result
    def self.success
      new(:success)
    end

    def self.failed(error)
      new(:failed, error: error)
    end

    attr_reader :error

    def initialize(status, error: nil)
      @status = status
      @error  = error
    end

    def success?
      @status == :success
    end

    def failed?
      @status == :failed
    end
  end

  def self.perform(organization:)
    new(organization: organization).perform
  end

  def initialize(organization:)
    @organization = organization
  end

  # Public: Migrate an Organizations default repository permission to none.
  #
  # Examples
  #
  #   org = Organization.first
  #
  #   # Succeeded
  #   OrganizationDefaultRepositoryPermissionMigrator.perform(organization: org)
  #   # => #<OrganizationDefaultRepositoryPermissionMigrator::Result:0x007f8a2b769a28
  #      @error=nil,
  #      @status=:success>
  #
  #   # Failed
  #   OrganizationDefaultRepositoryPermissionMigrator.perform(organization: org)
  #   # => #<OrganizationDefaultRepositoryPermissionMigrator::Result:0x007f8a2b708188
  #     @error="Organization: 1 doesn't have any users",
  #     @status=:failed>
  #
  # Returns a OrganizationDefaultRepositoryPermissionMigrator::Result.
  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def perform
    base_message = "Organization: #{organization.id} doesn't have any users"

    users = organization.users.to_a
    return Result.failed(base_message) if users.empty?

    org_admin_users = users.keep_if { |user| organization_admin_user?(user) }
    return Result.failed("#{base_message} that are org admins") if org_admin_users.empty?

    org_admin = org_admin_users.sample

    begin
      github_organization = GitHubOrganization.new(org_admin.github_client, organization.github_id)
      github_organization.update_default_repository_permission!("none")
    rescue GitHub::Error => err
      return Result.failed("For Organization #{organization.id}: #{err.message}")
    end

    Result.success
  end
  # rubocop:enable AbcSize
  # rubocop:enable MethodLength

  private

  def organization_admin_user?(user)
    github_organization = GitHubOrganization.new(user.github_client, organization.github_id)
    github_organization.admin?(user.github_user.login_no_cache)
  end
end
