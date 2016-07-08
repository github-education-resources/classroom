# frozen_string_literal: true
class OrganizationService
  def initialize(new_organization_params, creator, hook_url)
    @new_organization_params = new_organization_params
    @creator = creator
    @hook_url = hook_url
  end

  def build_organization
    unless Classroom.flipper[:explicit_assignment_submission].enabled? @creator
      return Organization.new(@new_organization_params)
    end
    github_organization = GitHubOrganization.new(@creator.github_client, @new_organization_params[:github_id])
    hook = github_organization.create_org_hook(config: { url: hook_url })
    Organization.new(@new_organization_params.tap { |hash| hash[:webhook_id] = hook.id })
  end
end
