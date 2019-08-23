# frozen_string_literal: true

require "rails_helper"

describe "default public_repo", type: :view do
  let(:organization) { classroom_org }

  it "defaults public_repo to true if the organization does not have private repos" do
    no_private_repos_plan = { owned_private_repos: 0, private_repos: 0 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(no_private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(no_private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")

    @assignment = Assignment.new
    @organization = organization
    render template: "assignments/new"
    expect(response.body).to include("value=\"public\" checked=\"checked\" name=\"assignment[visibility]\"")
    expect(response.body).to include("disabled=\"disabled\" type=\"radio\" value=\"private\" name=\"assignment[visibility]\"")
  end

  it "defaults public_repo to false if the organization has private repos" do
    private_repos_plan = { owned_private_repos: 0, private_repos: 100 }
    allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(private_repos_plan)
    allow_any_instance_of(Organization).to receive(:plan).and_return(private_repos_plan)
    stub_template("organizations/_organization_banner.html.erb" => "")

    @assignment = Assignment.new
    @organization = organization
    render template: "assignments/new"
    expect(response.body).to include("value=\"public\" name=\"assignment[visibility]\"")
    expect(response.body).to include("value=\"private\" checked=\"checked\" name=\"assignment[visibility]\"")
  end
end
