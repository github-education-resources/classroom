require 'rails_helper'

RSpec.describe AssignmentInvitationsController, type: :controller do
  describe 'GET #show' do
    let(:invitation) { create(:assignment_invitation_with_assignment) }

    describe 'unauthenticated request' do
      it 'redirects the new user to sign in with GitHub' do
        get :show, id: invitation.key
        expect(response).to redirect_to(login_path)
      end
    end

    describe 'authenticated request' do
      let(:user) { create(:user) }

      before(:each) do
        session[:user_id] = user.id
      end

      it 'will set the correct invitation' do
        get :show, id: invitation.key
        expect(assigns(:invitation)).to_not be_nil
      end
    end
  end

  describe 'GET #accept_invitation' do
    let(:invitation)   { create(:assignment_invitation_with_assignment) }
    let(:organization) { invitation.assignment.organization }

    let(:user) { create(:user) }

    before(:each) do
      session[:user_id] = user.id

      @stub_values = {
        team_id:        12,
        team_name:      'Team: 1',
        user_login:     'user',
        repo_id:        8_675_309,
        repo_name:      "#{invitation.assignment.title}: 1",
        full_repo_name: "user/#{invitation.assignment.title.parameterize}-1"
      }

      @request_stubs = []
    end

    after(:each) do
      @request_stubs.each do |request_stub|
        expect(request_stub).to have_been_requested.once
      end
    end

    describe 'successful invitation' do
      it 'redeems the users invitation and return a successul json message' do
        @request_stubs << stub_github_organization(organization.github_id,
                                                   login: organization.title,
                                                   id: organization.github_id)

        @request_stubs << stub_create_github_team(organization.github_id,
                                                  { name: @stub_values[:team_name], permission: 'push' },
                                                  id: @stub_values[:team_id])

        @request_stubs << stub_github_user(nil, login: @stub_values[:user_login])
        @request_stubs << stub_add_team_membership(@stub_values[:team_id], @stub_values[:user_login], state: 'pending')

        repo_options = {
          has_issues:    true,
          has_wiki:      true,
          has_downloads: true,
          team_id:       @stub_values[:team_id],
          private:       false,
          name:          @stub_values[:repo_name]
        }

        @request_stubs << stub_create_github_organization_repo(organization.title,
                                                               repo_options,
                                                               id: @stub_values[:repo_id],
                                                               name: @stub_values[:repo_name])

        @request_stubs << stub_github_repo(@stub_values[:repo_id], full_name: @stub_values[:full_repo_name])
        @request_stubs << stub_github_team_repository?(@stub_values[:team_id], @stub_values[:full_repo_name], 204, nil)

        get :accept_invitation, id: invitation.key, format: :json

        expect(response).to have_http_status(:created)
      end
    end
  end
end
