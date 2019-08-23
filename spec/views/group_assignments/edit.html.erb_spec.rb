# frozen_string_literal: true

require "rails_helper"

describe "default public_repo", type: :view do
  let(:organization) { classroom_org }

  it "defaults public_repo to true if the organization does not have private repos" do
    no_private_repos_plan = { owned_private_repos: 0, private_repos: 0 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(no_private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(no_private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")
    stub_template("group_assignments/_delete_group_assignment_modal.html" => "")

    @group_assignment = GroupAssignment.new
    @organization = organization
    render template: "group_assignments/edit"

    public_checked = "value=\"public\" checked=\"checked\" name=\"group_assignment[visibility]\""
    private_unchecked = "disabled=\"disabled\" type=\"radio\" value=\"private\" name=\"group_assignment[visibility]\""
    expect(response.body).to include(public_checked)
    expect(response.body).to include(private_unchecked)
  end

  it "defaults public_repo to false if the organization has private repos" do
    private_repos_plan = { owned_private_repos: 0, private_repos: 100 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")
    stub_template("group_assignments/_delete_group_assignment_modal.html" => "")

    @group_assignment = GroupAssignment.new
    @organization = organization
    render template: "group_assignments/edit"

    public_unchecked = "value=\"public\" name=\"group_assignment[visibility]\""
    private_checked = "value=\"private\" checked=\"checked\" name=\"group_assignment[visibility]\""
    expect(response.body).to include(public_unchecked)
    expect(response.body).to include(private_checked)
  end
end
