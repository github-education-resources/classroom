# frozen_string_literal: true

require "rails_helper"

describe "display student username", type: :view do
  let(:organization) { classroom_org }
  let(:assignment)   { create(:assignment, organization: organization) }

  before do
    organization.users.push(create(:user, uid: 90, token: "asdfsad4333"))
    organization.roster = create(:roster)
    organization.roster.roster_entries.push(RosterEntry.create(
                                              identifier: "student",
                                              roster: organization.roster,
                                              user_id: organization.users.last
    ))
    organization.save!
    organization.roster.reload
    allow_any_instance_of(AssignmentRepoView::ShowView).to receive(:disabled?).and_return(true)
    allow_any_instance_of(AssignmentRepoView::ShowView).to receive(:github_user_url).and_return("")
    allow_any_instance_of(AssignmentRepoView::ShowView).to receive(:github_user_login).and_return("")
    allow_any_instance_of(AssignmentRepoView::ShowView).to receive(:github_avatar_url).and_return("")
    allow_any_instance_of(AssignmentRepoView::ShowView).to receive(:github_repo_url).and_return("")
  end

  it "displays student's identifier if is a roster_entry" do
    assignment_repo = create(:assignment_repo,
      assignment: assignment,
      user: organization.users.last,
      github_repo_id: 34_534_534)
    render partial: "orgs/roster_entries/assignment_repos/linked_accepted",
           locals: { assignment_repo: assignment_repo,
                     current_roster_entry: organization.roster.roster_entries.last }
    expect(response).to include("student")
  end

  it "displays student github username if there is no roster_entry" do
    assignment_repo = create(:assignment_repo,
      assignment: assignment,
      user: organization.users.last,
      github_repo_id: 34_534_534)
    render partial: "orgs/roster_entries/assignment_repos/linked_accepted",
           locals: { assignment_repo: assignment_repo }
    expect(response).to_not include("student")
  end
end
