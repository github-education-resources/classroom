# frozen_string_literal: true

require "rails_helper"

describe "default public_repo", type: :view do
  let(:organization) { classroom_org }

  it "defaults public_repo to true if the organization does not have private repos" do
    no_private_repos_plan = { owned_private_repos: 0, private_repos: 0 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(no_private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(no_private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")
    stub_template("assignments/_delete_assignment_modal.html" => "")

    @assignment = Assignment.new
    @organization = organization
    render template: "assignments/edit"

    public_checked = "value=\"public\" checked=\"checked\" name=\"assignment[visibility]\""
    private_unchecked = "disabled=\"disabled\" type=\"radio\" value=\"private\" name=\"assignment[visibility]\""
    expect(response.body).to include(public_checked)
    expect(response.body).to include(private_unchecked)
  end

  it "defaults public_repo to false if the organization has private repos" do
    private_repos_plan = { owned_private_repos: 0, private_repos: 100 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")
    stub_template("assignments/_delete_assignment_modal.html" => "")

    @assignment = Assignment.new
    @organization = organization
    render template: "assignments/edit"

    public_unchecked = "value=\"public\" name=\"assignment[visibility]\""
    private_checked = "value=\"private\" checked=\"checked\" name=\"assignment[visibility]\""
    expect(response.body).to include(public_unchecked)
    expect(response.body).to include(private_checked)
  end
end
