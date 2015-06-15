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

        @invitation       = create(:assignment_invitation_with_assignment)
        @organization     = @invitation.assignment.organization
      end

      describe 'successful invitation' do
        it 'will redeem the users invitation and show them the success layout' do
          full_repo_name = 'org/test_repo'
          repo_id        = 123
          team_id        = 1
          user_login     = 'user_login'

          ###########
          ## Setup ##
          ###########

          # Get organization
          stub_github_organization(@organization.github_id, login: @organization.title, id: @organization.github_id)

          # Get admin member of org
          stub_users_github_organization_membership(@organization.title, state: 'active', role: 'admin')

          # Create GitHub Team
          team_number = @organization.repo_accesses.count + 1
          stub_create_github_team(@organization.github_id,
                                  { name: "Team: #{team_number}", permission: 'push' },
                                  id: team_id)

          #################
          ## repo_access ##
          #################

          # Get GitHub User info
          stub_github_user(nil, login: user_login)

          # Add GitHub user to team
          stub_add_team_membership(team_id, user_login, state: 'pending')

          #####################
          ## assignment_repo ##
          #####################

          options = {
            private:       true,
            has_issues:    true,
            has_wiki:      true,
            has_downloads: true,
            team_id:       team_id,
            name:          "#{@invitation.assignment.title}: #{@invitation.assignment.assignment_repos.count + 1}"
          }

          stub_create_github_organization_repo(@organization.title,
                                               options,
                                               id: repo_id,
                                               name: @invitation.assignment.title)

          stub_github_repo(repo_id, { full_name: full_repo_name })
          stub_github_team_repository?(team_id, full_repo_name, 204, nil)

          get :show, id: @invitation.key

          assert_template :success
          assert 200, @response.status
        end
      end
    end
  end
end
