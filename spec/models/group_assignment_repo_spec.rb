# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentRepo, type: :model do
  context "with created objects", :vcr do
    let(:organization) { classroom_org }
    let(:student)      { classroom_student }
    let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }
    let(:grouping)     { create(:grouping, organization: organization) }

    let(:group_assignment) do
      create(
        :group_assignment,
        grouping: grouping,
        title: "Learn JavaScript",
        organization: organization,
        public_repo: true,
        starter_code_repo_id: 1_062_897
      )
    end

    let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name[0..39]).id }
    let(:group) { create(:group, grouping: grouping, github_team_id: github_team_id, repo_accesses: [repo_access]) }
    subject { create(:group_assignment_repo, group_assignment: group_assignment, group: group, github_repo_id: 42) }

    describe "callbacks", :vcr do
      describe "before_destroy" do
        describe "#silently_destroy_github_repository" do
          it "deletes the repository from GitHub" do
            subject.destroy
            expect(WebMock).to have_requested(:delete, github_url("/repositories/#{subject.github_repo_id}"))
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
          expect(subject.default_branch).to eql(subject.github_repository.default_branch)
        end
      end

      describe "#slug" do
        it "returns the group assignment's slug" do
          expect(subject.slug).to eq(group_assignment.slug)
        end
      end
    end

    describe "#github_team" do
      it "returns the github team of the group" do
        expect(subject.github_team).to be(group.github_team)
      end
    end
  end
end
