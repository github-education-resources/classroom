# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentRepo, type: :model do
  context 'with created objects', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org  }
    let(:student)      { GitHubFactory.create_classroom_student    }

    let(:assignment) do
      Assignment.create(creator: organization.users.first,
                        title: 'Learn Ruby',
                        organization: organization,
                        public_repo: false,
                        starter_code_repo_id: 1_062_897)
    end

    before(:each) do
      @assignment_repo = AssignmentRepo.create(assignment: assignment, user: student)
    end

    after(:each) do
      @assignment_repo.destroy if @assignment_repo
    end

    describe 'callbacks' do
      describe 'before_validation' do
        describe '#create_github_repository' do
          it 'creates the repository on GitHub' do
            expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
          end
        end

        describe '#push_starter_code' do
          it 'pushes the starter code to the GitHub repository' do
            import_github_url = github_url("/repositories/#{@assignment_repo.github_repo_id}/import")
            expect(WebMock).to have_requested(:put, import_github_url)
          end
        end

        describe '#adds_user_as_collaborator' do
          it 'adds the user as a collaborator to the GitHub repository' do
            github_user_login = GitHubUser.new(student.github_client, student.uid).login
            add_user_request = "/repositories/#{@assignment_repo.github_repo_id}/collaborators/#{github_user_login}"

            expect(WebMock).to have_requested(:put, github_url(add_user_request))
          end
        end
      end

      describe 'before_destroy' do
        describe '#silently_destroy_github_repository' do
          it 'deletes the repository from GitHub' do
            repo_id = @assignment_repo.github_repo_id
            @assignment_repo.destroy

            expect(WebMock).to have_requested(:delete, github_url("/repositories/#{repo_id}"))
          end
        end
      end
    end

    describe '#creator' do
      it 'returns the assignments creator' do
        expect(@assignment_repo.creator).to eql(assignment.creator)
      end
    end
  end
end
