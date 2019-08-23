# frozen_string_literal: true

require "rails_helper"

describe "default public_repo", type: :view do
  let(:organization) { classroom_org }

  it "selects public_repo true if the assignment has public_repo set to true if no private repos are available" do
    no_private_repos_plan = { owned_private_repos: 0, private_repos: 0 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(no_private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(no_private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")
    stub_template("group_assignments/_delete_group_assignment_modal.html" => "")

    @group_assignment = create(:group_assignment, public_repo: true)
    @organization = organization
    render template: "group_assignments/edit"

    public_checked = "value=\"public\" checked=\"checked\" name=\"group_assignment[visibility]\""
    private_unchecked = "disabled=\"disabled\" type=\"radio\" value=\"private\" name=\"group_assignment[visibility]\""
    expect(response.body).to include(public_checked)
    expect(response.body).to include(private_unchecked)
  end

  it "selects public_repo true if the assignment has public_repo set to true even if private repos are available" do
    no_private_repos_plan = { owned_private_repos: 0, private_repos: 100 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(no_private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(no_private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")
    stub_template("group_assignments/_delete_group_assignment_modal.html" => "")

    @group_assignment = create(:group_assignment, public_repo: true)
    @organization = organization
    render template: "group_assignments/edit"

    public_checked = "value=\"public\" checked=\"checked\" name=\"group_assignment[visibility]\""
    private_unchecked = "value=\"private\" name=\"group_assignment[visibility]\""
    expect(response.body).to include(public_checked)
    expect(response.body).to include(private_unchecked)
  end

  it "selects public_repo false if the assignment has public_repo set to false" do
    private_repos_plan = { owned_private_repos: 0, private_repos: 100 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")
    stub_template("group_assignments/_delete_group_assignment_modal.html" => "")

    @group_assignment = create(:group_assignment, public_repo: false)
    @organization = organization
    render template: "group_assignments/edit"

    public_unchecked = "value=\"public\" name=\"group_assignment[visibility]\""
    private_checked = "value=\"private\" checked=\"checked\" name=\"group_assignment[visibility]\""
    expect(response.body).to include(public_unchecked)
    expect(response.body).to include(private_checked)
  end
end
