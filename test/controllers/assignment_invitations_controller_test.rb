require 'test_helper'

class AssignmentInvitationsControllerTest < ActionController::TestCase
  before do
    @controller = AssignmentInvitationsController.new
  end

  describe '#show' do
    before do
      @invitation = create(:assignment_invitation_with_assignment)
    end

    describe 'unathenticated request' do
      it 'will redirect the new user to sign in with GitHub' do
        get :show, id: @invitation.key
        assert_redirected_to login_path
      end
    end

    describe 'authenticated request' do
      before do
        @user             = create(:user)
        session[:user_id] = @user.id
      end

      it 'will set the correct invitation' do
        get :show, id: @invitation.key
        assert_not_nil assigns(:invitation)
      end
    end
  end

  describe '#accept_invitation' do
    before do
      @user             = create(:user)
      session[:user_id] = @user.id

      @invitation       = create(:assignment_invitation_with_assignment)
      @organization     = @invitation.assignment.organization

      @stub_values = {
        team_id:        12,
        team_name:      'Team 1',
        user_login:     'user',
        repo_id:        8_675_309,
        repo_name:      "#{@invitation.assignment.title}: 1",
        full_repo_name: "user/#{@invitation.assignment.title.parameterize}-1"
      }
    end

    describe 'successful invitation' do
      it 'will redeem the users invitation and return a successul json message' do
        stub_github_organization(@organization.github_id, login: @organization.title, id: @organization.github_id)

        stub_users_github_organization_membership(@organization.title, state: 'active', role: 'admin')

        team_number = @organization.repo_accesses.count + 1

        stub_create_github_team(
          @organization.github_id,
          { name: "Team: #{team_number}", permission: 'push' },
          id: @stub_values[:team_id]
        )

        stub_github_user(nil, login: @stub_values[:user_login])

        stub_add_team_membership(@stub_values[:team_id], @stub_values[:user_login], state: 'pending')

        repo_options = {
          has_issues:    true,
          has_wiki:      true,
          has_downloads: true,
          team_id:       @stub_values[:team_id],
          private:       false,
          name:          @stub_values[:repo_name]
        }

        stub_create_github_organization_repo(@organization.title,
                                             repo_options,
                                             id: @stub_values[:repo_id],
                                             name: @stub_values[:repo_name])

        stub_github_repo(@stub_values[:repo_id], full_name: @stub_values[:full_repo_name])
        stub_github_team_repository?(@stub_values[:team_id], @stub_values[:full_repo_name], 204, nil)

        get :accept_invitation, format: :json, id: @invitation.key

        response_body = JSON.parse(@response.body)
        assert 'Success!', response_body[:message]
        assert 201, @response.status
      end
    end
  end
end
