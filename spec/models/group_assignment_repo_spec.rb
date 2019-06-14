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

    before(:each) do
      github_team_id = organization.github_organization.create_team(Faker::Team.name[0..39]).id
      @group = create(:group, grouping: grouping, github_team_id: github_team_id)
      @group.repo_accesses << repo_access
    end

    after(:each) do
      repo_access.destroy
      @group_assignment_repo.destroy if @group_assignment_repo.present?
      organization.github_organization.delete_team(@group.github_team_id)
    end

    describe "callbacks", :vcr do
      describe "before_validation" do
        context "success" do
          before(:each) do
            @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: @group)
          end

          describe "#create_github_repository" do
            it "creates the repository on GitHub" do
              expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
            end

            it "sets the GitHub database id and GraphQL node_id" do
              expect(@group_assignment_repo.id).to_not be_nil
              expect(@group_assignment_repo.github_global_relay_id).to_not be_nil
            end
          end

          describe "#push_starter_code" do
            it "pushes the starter code to the GitHub repository" do
              import_github_repo_url = github_url("/repositories/#{@group_assignment_repo.github_repo_id}/import")
              expect(WebMock).to have_requested(:put, import_github_repo_url)
            end
          end

          describe "#add_team_to_github_repository" do
            it "adds the team to the repository" do
              github_repo = GitHubRepository.new(organization.github_client, @group_assignment_repo.github_repo_id)
              add_github_team_url = github_url("/teams/#{@group.github_team_id}/repos/#{github_repo.full_name}")
              expect(WebMock).to have_requested(:put, add_github_team_url)
            end

            context "when students_are_repo_admins is true" do
              before do
                group_assignment.update(students_are_repo_admins: true)
                @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: @group)
              end

              it "adds the team to the repository" do
                github_repo = GitHubRepository.new(organization.github_client, @group_assignment_repo.github_repo_id)
                add_github_team_url = github_url("/teams/#{@group.github_team_id}/repos/#{github_repo.full_name}")
                permission_param = { permission: "admin" }
                expect(WebMock).to have_requested(:put, add_github_team_url)
                  .with(body: hash_including(permission_param))
              end
            end
          end
        end

        context "failure" do
          after(:each) do
            regex = %r{#{github_url("/repositories")}/\d+$}
            expect(WebMock).to have_requested(:delete, regex)
          end

          describe "#push_starter_code" do
            it "fails to push the starter code to the GitHub repository" do
              stub_request(:put, %r{#{github_url("/repositories")}/\d+/import$})
                .to_return(status: 500)
              expect { GroupAssignmentRepo.create!(group_assignment: group_assignment, group: @group) }
                .to raise_error(GitHub::Error)
            end
          end

          describe "#add_team_to_github_repository" do
            it "fails to add team to the repository" do
              USERNAME_REGEX = GitHub::USERNAME_REGEX
              REPOSITORY_REGEX = GitHub::REPOSITORY_REGEX
              regex = %r{#{github_url("/teams/#{@group.github_team_id}/repos/")}#{USERNAME_REGEX}\/#{REPOSITORY_REGEX}$}
              stub_request(:put, regex)
                .to_return(status: 500)
              expect { GroupAssignmentRepo.create!(group_assignment: group_assignment, group: @group) }
                .to raise_error(GitHub::Error)
            end
          end
        end
      end

      describe "before_destroy" do
        before(:each) do
          @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: @group)
        end

        describe "#destroy_github_repository" do
          it "deletes the repository from GitHub" do
            repo_id = @group_assignment_repo.github_repo_id
            @group_assignment_repo.destroy

            expect(WebMock).to have_requested(:delete, github_url("/repositories/#{repo_id}"))
          end
        end
      end
    end

    describe "#creator" do
      before(:each) do
        @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: @group)
      end

      it "returns the group assignments creator" do
        expect(@group_assignment_repo.creator).to eql(group_assignment.creator)
      end
    end
  end
end
