# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentInvitationsController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { GitHubFactory.create_classroom_student   }

  let(:student_identifier_type) { create(:student_identifier_type, organization: organization) }

  describe 'GET #show', :vcr do
    let(:invitation) { create(:assignment_invitation) }

    context 'unauthenticated request' do
      it 'redirects the new user to sign in with GitHub' do
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(login_path)
      end
    end

    context 'authenticated request' do
      let(:user) { GitHubFactory.create_classroom_student }

      before(:each) do
        sign_in(user)
      end

      it 'will bring you to the page' do
        get :show, params: { id: invitation.key }
        expect(response).to have_http_status(:success)
      end
    end

    context 'student identifier required' do
      before(:each) do
        invitation.assignment.student_identifier_type = student_identifier_type
        invitation.assignment.save
        sign_in(user)
      end

      it 'redirects to the identifier page' do
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(identifier_assignment_invitation_path)
      end

      context 'user already has an identifier value' do
        before do
          StudentIdentifier.create(organization: organization,
                                   user: user,
                                   student_identifier_type: student_identifier_type,
                                   value: 'test value')
        end

        it 'will bring user to the page' do
          get :show, params: { id: invitation.key }
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe 'PATCH #submit_identifier', :vcr do
    let(:invitation) { create(:assignment_invitation) }
    let(:options)    { { value: 'test value' }        }

    before(:each) do
      invitation.assignment.student_identifier_type = student_identifier_type
      invitation.assignment.save
      sign_in(user)
    end

    after(:each) do
      StudentIdentifier.destroy_all
    end

    it 'creates the students identifier' do
      patch :submit_identifier, params: { id: invitation.key, student_identifier: options }
      expect(StudentIdentifier.count).to eql(1)
    end

    it 'has correct identifier value' do
      patch :submit_identifier, params: { id: invitation.key, student_identifier: options }
      expect(StudentIdentifier.first.value).to eql('test value')
    end

    it 'redirects to the accepting page' do
      patch :submit_identifier, params: { id: invitation.key, student_identifier: options }
      expect(response).to redirect_to(assignment_invitation_path)
    end
  end

  describe 'PATCH #accept_invitation', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:user)         { GitHubFactory.create_classroom_student   }

    let(:assignment) do
      create(:assignment, title: 'Learn you Node', starter_code_repo_id: 1_062_897, organization: organization)
    end

    let(:invitation) { create(:assignment_invitation, assignment: assignment) }

    before(:each) do
      request.env['HTTP_REFERER'] = "http://classroomtest.com/group-assignment-invitations/#{invitation.key}"
      sign_in(user)
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    it 'redeems the users invitation' do
      patch :accept_invitation, params: { id: invitation.key }
      expect(user.assignment_repos.count).to eql(1)
    end
  end

  describe 'GET #successful_invitation' do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:user)         { GitHubFactory.create_classroom_student   }

    let(:assignment) do
      create(:assignment, title: 'Learn Clojure', starter_code_repo_id: 1_062_897, organization: organization)
    end

    let(:invitation) { create(:assignment_invitation, assignment: assignment) }

    before(:each) do
      sign_in(user)
      result = AssignmentRepo::Creator.perform(assignment: assignment, invitee: user)
      @assignment_repo = result.assignment_repo
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    context 'github repository deleted after accepting a invitation successfully', :vcr do
      before do
        organization.github_client.delete_repository(@assignment_repo.github_repo_id)
        get :successful_invitation, params: { id: invitation.key }
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
