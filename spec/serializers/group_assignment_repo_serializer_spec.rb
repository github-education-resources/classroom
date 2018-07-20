# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::GroupAssignmentRepoSerializer, type: :serializer do
  let(:organization) { classroom_org     }
  let(:student)      { classroom_student }

  # let(:grouping)     { create(:grouping, organization: organization) }
  # let(:group)        { create(:group, grouping: grouping, title: "Test Group") }

  # let(:group_assignment) do
  #   create(:group_assignment,
  #          grouping: grouping,
  #          title: "Learn Clojure",
  #          organization: organization)
  # end

  # let(:group_assignment_repo) { create(:group_assignment_repo, group_assignment: group_assignment, group: group) }

  describe "AssignmentRepoSerializer attributes check", :vcr do
    before(:each) do
      @grouping = create(:grouping, organization: organization)
      @group = create(:group, grouping: @grouping, title: "Test Group")

      @group_assignment = create(:group_assignment,
        grouping: @grouping,
        title: "Learn Clojure",
        organization: organization)

      @group_assignment_repo = create(:group_assignment_repo, group_assignment: @group_assignment, group: @group)

      @group_assignment_repo_json = described_class.new(@group_assignment_repo).to_json
    end

    it "returns group title as username" do
      expect(@group_assignment_repo_json[:username]).to eq(group.title)
    end

    it "returns github repo url" do
      expect(@group_assignment_repo_json[:repoUrl]).to eq(group_assignment_repo.github_repository.html_url)
    end

    it "returns comma separated list of usernames as display name" do
      expect(@group_assignment_repo_json[:displayName]).to eq(group.users.join(", "))
    end
  end
end
