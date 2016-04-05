require 'rails_helper'

RSpec.describe AssignmentRepo, type: :model do
  context 'with created objects', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org  }
    let(:student)      { GitHubFactory.create_classroom_student    }

    let(:assignment) do
      Assignment.create(creator: organization.users.first,
                        title: 'Learn Ruby',
                        organization: organization,
                        # public_repo: false,
                        starter_code_repo_id: 1_062_897)
    end

    before(:each) do
      @assignment_repo = AssignmentRepo.create(assignment: assignment, user: student)
    end

    after(:each) do
      AssignmentRepo.destroy_all
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

      # describe 'after_create' do
      #   describe '#copy_starter_repo_open_issues' do
      #     it 'invokes copy_starter_repo_open_issues if copy_open_issues is true' do
      #
      #     end
      #
      #     it 'does not invoke copy_starter_repo_open_issues if copy_open_issues is false' do
      #
      #     end
      #   end
      # end

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

    describe '#user' do
      it 'returns the user' do
        expect(@assignment_repo.user).to eql(student)
      end

      context 'assignment_repo has a user through a repo_access' do
        before do
          assignment.update_attributes(title: "#{assignment.title}-2")
          repo_access = RepoAccess.create(user: student, organization: organization)
          @assignment_repo = AssignmentRepo.create(assignment: assignment, repo_access: repo_access)
        end

        after do
          RepoAccess.destroy_all
        end

        it 'returns the user' do
          expect(@assignment_repo.user).to eql(student)
        end
      end
    end

    describe '#copy_starter_repo_open_issues' do
      include ActiveJob::TestHelper

      it 'enqueues the CopyOpenIssues background job' do
        job_args = [@assignment_repo.creator, assignment.starter_code_repo_id, @assignment_repo.github_repo_id]
        assert_enqueued_with(job: CopyOpenIssuesJob, args: job_args, queue: 'issue_copier') do
          @assignment_repo.copy_starter_repo_open_issues
        end
      end

      it 'does not enqueue the CopyOpenIssues background job if starter_code_repo_id is not present' do
        assignment.starter_code_repo_id = nil
        assert_no_enqueued_jobs do
          @assignment_repo.copy_starter_repo_open_issues
        end
      end
    end
  end
end
