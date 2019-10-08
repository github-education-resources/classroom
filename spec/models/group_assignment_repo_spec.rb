# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentRepo, type: :model do
  context "with created objects" do
    let(:organization) { classroom_org }
    let(:student)      { classroom_student }
    let(:repo_access)  do
      stub_org_request(organization.github_id)
      stub_user_request(student.uid)
      stub_check_org_membership_request(organization.github_id, student.github_user.login)
      stub_update_org_membership_request(
        organization.github_organization.login, user: student.github_user.login
      )
      stub_update_org_membership_request(
        organization.github_organization.login, state: "active"
      )
      RepoAccess.create(user: student, organization: organization)
    end

    let(:grouping) { create(:grouping, organization: organization) }

    let(:group_assignment) do
      stub_repo_request(1_062_897)
      stub_repo_contents_request(1_062_897, empty: false)
      create(
        :group_assignment,
        grouping: grouping,
        title: "Learn JavaScript",
        organization: organization,
        public_repo: true,
        starter_code_repo_id: 1_062_897
      )
    end

    let(:github_team_id) do
      stub_create_team(organization, 123)
      123
    end

    let(:group) do
      user_login = repo_access.user.github_user.login
      stub_create_team_membership_request(github_team_id, user_login)
      create(:group, grouping: grouping, github_team_id: github_team_id, repo_accesses: [repo_access])
    end

    subject { create(:group_assignment_repo, group_assignment: group_assignment, group: group, github_repo_id: 42) }

    describe ".search" do
      let(:searchable_repo) { create(:group_assignment_repo, group_assignment: group_assignment) }

      before do
        expect(searchable_repo).to_not be_nil
      end

      it "searches by id" do
        results = GroupAssignmentRepo.search(searchable_repo.id)
        expect(results.to_a).to include(searchable_repo)
      end

      it "searches by github_repo_id" do
        results = GroupAssignmentRepo.search(searchable_repo.github_repo_id)
        expect(results.to_a).to include(searchable_repo)
      end

      it "does not return the assignment when it shouldn't" do
        results = GroupAssignmentRepo.search("spaghetto")
        expect(results.to_a).to_not include(searchable_repo)
      end
    end

    describe "callbacks" do
      describe "before_destroy" do
        describe "#silently_destroy_github_repository" do
          it "deletes the repository from GitHub" do
            stub_org_request(organization.github_id)
            stub_delete_repo_request(subject.github_repo_id)

            expect(stub_octokit_client).to receive(:delete_repository).with(subject.github_repo_id)
            subject.destroy
          end
        end
      end
    end

    context "delegations" do
      describe "#creator" do
        it "returns the group assignments creator" do
          expect(subject.creator).to eql(group_assignment.creator)
        end
      end

      describe "#starter_code_repo_id" do
        it "returns the group assignment's starter_code_repo_id" do
          expect(subject.starter_code_repo_id).to eql(group_assignment.starter_code_repo_id)
        end
      end

      describe "#github_team_id" do
        it "returns the group's github_team_id" do
          expect(subject.github_team_id).to eql(group.github_team_id)
        end
      end

      describe "#default_branch" do
        it "returns the github repository's default_branch" do
          stub_repo_request(subject.github_repo_id)
          stub_repo_default_branch_request(subject.github_repository.full_name)
          expect(subject.default_branch).to eql(subject.github_repository.default_branch)
        end
      end

      describe "#slug" do
        it "returns the group assignment's slug" do
          expect(subject.slug).to eq(group_assignment.slug)
        end
      end
    end

    describe "is sortable" do
      let(:github_team_id_two) do
        stub_create_team(organization, 456)
        456
      end

      let(:group_two) do
        user_login = repo_access.user.github_user.login
        stub_create_team_membership_request(github_team_id_two, user_login)
        create(:group, grouping: grouping, github_team_id: github_team_id_two, repo_accesses: [repo_access])
      end

      let(:group_assignment_repo_one) { create(:group_assignment_repo, group_assignment: group_assignment, group: group, github_repo_id: 1) }
      let(:group_assignment_repo_two) { create(:group_assignment_repo, group_assignment: group_assignment, group: group_two, github_repo_id: 2) }

      it "order_by_sort_mode sorts by 'Team name'" do
        expected_ordering = [group_assignment_repo_one, group_assignment_repo_two].sort_by { |repo| repo.group.title }
        actual_ordering = GroupAssignmentRepo.where(group_assignment: group_assignment).order_by_sort_mode("Team name")

        expect(actual_ordering).to eq(expected_ordering)
      end

      it "order_by_sort_mode sorts by 'Created at'" do
        expected_ordering = [group_assignment_repo_one, group_assignment_repo_two].sort_by(&:created_at)
        actual_ordering = GroupAssignmentRepo.where(group_assignment: group_assignment).order_by_sort_mode("Created at")

        expect(actual_ordering).to eq(expected_ordering)
      end
    end

    describe "is searchable" do
      let(:github_team_id_two) do
        stub_create_team(organization, 456)
        456
      end

      let(:group_two) do
        user_login = repo_access.user.github_user.login
        stub_create_team_membership_request(github_team_id_two, user_login)
        create(:group, grouping: grouping, github_team_id: github_team_id_two, repo_accesses: [repo_access])
      end

      let(:group_assignment_repo_one) { create(:group_assignment_repo, group_assignment: group_assignment, group: group, github_repo_id: 1) }
      let(:group_assignment_repo_two) { create(:group_assignment_repo, group_assignment: group_assignment, group: group_two, github_repo_id: 2) }

      it "filter_by_sort_mode searches by 'Team name'" do
        query = group_assignment_repo_one.group.title

        expected = [group_assignment_repo_one, group_assignment_repo_two].select { |r| r.group.title == query }
        actual = GroupAssignmentRepo.where(group_assignment: group_assignment).filter_by_search(query)

        expect(actual).to eq(expected)
      end
    end

    describe "#github_team" do
      it "returns the github team of the group" do
        expect(subject.github_team).to be(group.github_team)
      end
    end

    describe "#github_team" do
      let(:group_assignment_repo) { create(:group_assignment_repo, group_assignment: group_assignment, group: group) }

      it "returns a NillGitHubTeam when group is nil" do
        group_assignment_repo.group.delete
        expect(group_assignment_repo.reload.github_team).to be_a(NullGitHubTeam)
      end

      it "returns a valid GitHubTeam when group exists" do
        expect(group_assignment_repo.github_team).to be_a(GitHubTeam)
      end
    end

    describe "number of commits" do
      it "returns the total number of commits when there is no starter repo" do
        stub_repo_request(subject.github_repo_id)
        stub_repo_contributors_stats_request(subject.github_repository.full_name, 1)
        subject.assignment.update_attributes(starter_code_repo_id: nil)
        expect(subject.number_of_commits).to eq(1)
      end

      it "subtracts the number of starter repo commits" do
        starter_repo_id = subject.assignment.starter_code_repo_id
        expect(starter_repo_id).to_not be_nil
        stub_repo_request(starter_repo_id)
        stub_repo_contents_request(starter_repo_id, empty: false)
        stub_repo_request(subject.github_repo_id)

        total_commits = 3
        starter_repo_commits = 1
        stub_repo_contributors_stats_request(subject.github_repository.full_name, total_commits)
        stub_repo_contributors_stats_request(subject.assignment.starter_code_repository.full_name, starter_repo_commits)
        expect(subject.number_of_commits).to eq(total_commits - starter_repo_commits)
      end
    end
  end
end
