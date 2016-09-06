# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentInvitationsController, type: :controller do
  describe 'GET #show', :vcr do
    let(:invitation) { create(:assignment_invitation) }

    context 'unauthenticated request' do
      it 'redirects the new user to sign in with GitHub' do
        get :show, id: invitation.key
        expect(response).to redirect_to(login_path)
      end
    end

    context 'authenticated request' do
      let(:user) { GitHubFactory.create_classroom_student }

      before(:each) do
        sign_in(user)
      end

      it 'will bring you to the page' do
        get :show, id: invitation.key
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH #accept_invitation', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:user)         { GitHubFactory.create_classroom_student   }

    let(:assignment) do
      Assignment.create(creator: organization.users.first,
                        title: 'ruby-project',
                        slug: 'ruby-project',
                        starter_code_repo_id: '1062897',
                        organization: organization,
                        public_repo: false)
    end

    let(:invitation) { AssignmentInvitation.create(assignment: assignment) }

    before(:each) do
      request.env['HTTP_REFERER'] = "http://classroomtest.com/group-assignment-invitations/#{invitation.key}"
      sign_in(user)
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    it 'redeems the users invitation' do
      patch :accept_invitation, id: invitation.key
      expect(user.assignment_repos.count).to eql(1)
    end

    context 'github repository creation fails' do
      before do
        allow_any_instance_of(AssignmentRepo)
          .to receive(:create_github_repository)
          .and_raise(GitHub::Error)
      end

      it 'does not create a an assignment repo record' do
        patch :accept_invitation, id: invitation.key

        expect(assignment.assignment_repos.count).to eq(0)
      end
    end

    context 'github repository with the same name already exists' do
      before do
        assignment_repo = AssignmentRepo.create!(assignment: assignment, user: user)
        @original_repository = organization.github_client.repository(assignment_repo.github_repo_id)
        assignment_repo.delete
        patch :accept_invitation, id: invitation.key
      end

      it 'creates a new assignment repo' do
        expect(user.assignment_repos.count).to eql(1)
      end

      it 'new repository name has expected suffix' do
        expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
          .with(body: /^.*#{@original_repository.name}-1.*$/)
      end

      after do
        organization.github_client.delete_repository(@original_repository.id)
        AssignmentRepo.destroy_all
      end
    end

    context 'github import fails' do
      before do
        allow_any_instance_of(GitHubRepository)
          .to receive(:get_starter_code_from)
          .and_raise(GitHub::Error)
      end

      it 'removes the repository on GitHub' do
        patch :accept_invitation, id: invitation.key
        expect(WebMock).to have_requested(:delete, %r{\A#{github_url('/repositories')}/\d+\z})
      end
    end
  end

  describe 'GET #successful_invitation' do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:user)         { GitHubFactory.create_classroom_student   }

    let(:assignment) do
      Assignment.create(creator: organization.users.first,
                        title: 'ruby-project',
                        slug: 'ruby-project',
                        starter_code_repo_id: '1062897',
                        organization: organization,
                        public_repo: false)
    end

    let(:invitation) { AssignmentInvitation.create(assignment: assignment) }

    before(:each) do
      sign_in(user)
      @assignment_repo = AssignmentRepo.create!(assignment: assignment, user: user)
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    context 'delete github repository after accepting a invitation successfully', :vcr do
      before do
        organization.github_client.delete_repository(@assignment_repo.github_repo_id)
        get :successful_invitation, id: invitation.key
      end

      it 'deletes the old assignment repo' do
        expect { @assignment_repo.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'creates a new assignment repo for the student' do
        expect(AssignmentRepo.last.id).not_to eq(@assignment_repo.id)
      end
    end
  end
end
