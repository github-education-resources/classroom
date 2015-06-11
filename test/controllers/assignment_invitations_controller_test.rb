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
          repo_id    = 123
          team_id    = 1
          user_login = 'user_login'

          #################
          ## repo_access ##
          #################

          # Get organization
          stub_github_organization(@organization.github_id, login: @organization.title, id: @organization.github_id)

          # Get admin member of org
          stub_users_github_organization_membership(@organization.title, state: 'active', role: 'admin')

          # No GitHub Team is present
          stub_github_team(nil, nil)

          # Create GitHub Team
          team_number = @organization.repo_accesses.count + 1
          stub_create_github_team(@organization.github_id,
                                  { name: "Team: #{team_number}", permission: 'push' },
                                  id: team_id)

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

          # Create GitHub Repo
          stub_create_github_organization_repo(@organization.title,
                                               options,
                                               id: repo_id,
                                               name: @invitation.assignment.title)

          # Return that the repo exists
          stub_github_repo(repo_id, true)

          get :show, id: @invitation.key

          assert_template :success
          assert 200, @response.status
        end
      end
    end
  end
end
