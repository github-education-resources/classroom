require 'rails_helper'

RSpec.describe AssignmentInvitationsController, type: :controller do
  describe 'GET #show' do
    let(:invitation) { create(:assignment_invitation) }

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

  describe 'GET #accept_invitation', :vcr do
    before(:each) do
      @organization = GitHubFactory.create_owner_classroom_org
      @user         = GitHubFactory.create_classroom_student

      @assignment  = Assignment.create(title: 'ruby-project', organization: @organization, public_repo: false)
      @invitation  = AssignmentInvitation.create(assignment: @assignment)

      session[:user_id] = @user.id
    end

    after(:each) do
      assignment_repo = @assignment.assignment_repos.last
      client          = @organization.fetch_owner.github_client

      repo_id         = assignment_repo.github_repo_id
      team_id         = assignment_repo.repo_access.github_team_id

      client.delete_team(team_id)
      client.delete_repository(repo_id)
    end

    it 'redeems the users invitation' do
      get :accept_invitation, id: @invitation.key, format: :json

      assert_requested :post, github_url("/organizations/#{@organization.github_id}/teams")
      assert_requested :post, github_url("/organizations/#{@organization.github_id}/repos")

      expect(@assignment.assignment_repos.count).to eql(1)
      expect(@user.repo_accesses.count).to eql(1)
    end
  end
end
