# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentRepo, type: :model do
  context 'with created objects', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org  }
    let(:student)      { GitHubFactory.create_classroom_student    }

    let(:assignment) do
      Assignment.create(creator: organization.users.first,
                        title: 'Learn Ruby',
                        slug: 'learn-ruby',
                        organization: organization,
                        public_repo: true,
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

          context 'when students_are_repo_admins is true' do
            before do
              assignment.update(students_are_repo_admins: true)
              @assignment_repo = AssignmentRepo.create(assignment: assignment, user: student)
            end

            it 'adds the user as a collaborator to the GitHub repository with admin permission' do
              github_user_login = GitHubUser.new(student.github_client, student.uid).login
              add_user_request = "/repositories/#{@assignment_repo.github_repo_id}/collaborators/#{github_user_login}"

              expect(WebMock).to have_requested(:put, github_url(add_user_request)).with(body: { permission: 'admin' })
            end
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

    describe '#nameable' do
      context 'github repository with the same name does not exist' do
        it 'has correct repository name' do
          expect(@assignment_repo.repo_name).to eql("#{assignment.slug}-#{student.github_user.login}")
        end
      end

      context 'github repository with the same name already exists' do
        let(:new_assignment_repo) { AssignmentRepo.create(assignment: assignment, user: student) }

        it 'has correct repository name' do
          expect(new_assignment_repo.repo_name).to eql("#{assignment.slug}-#{student.github_user.login}-1")
        end

        context 'github repository name is too long' do
          let(:github_organization) { GitHubOrganization.new(organization.github_client, organization.github_id) }
          let(:long_repo_name) { "#{'a' * 60}-#{'u' * 39}" }

          before do
            github_organization.create_repository(long_repo_name, private: true, description: 'Nothing here')
            allow(new_assignment_repo).to receive(:base_name).and_return(long_repo_name)
          end

          it 'truncates the repository name into 100 characters' do
            expect(new_assignment_repo.generate_github_repo_name.length).to eql(100)
          end

          it 'does not remove the repository name suffix' do
            expect(new_assignment_repo.generate_github_repo_name).to end_with('-1')
          end

          after do
            github_organization.delete_repository("#{github_organization.login}/#{long_repo_name}")
          end
        end
      end
    end
  end
end
