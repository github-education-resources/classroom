require 'test_helper'

class InvitationsControllerTest < ActionController::TestCase
  before do
    @controller = InvitationsController.new
    @invitation   = invitations(:one)
  end

  describe '#show' do
    describe 'unathenticated request' do
      it 'will redirect the new user to sign in with GitHub' do
        get :show, { id: @invitation.key }
        assert_redirected_to login_path
      end
    end

    describe 'authenticated request' do
      before do
        @organization = @invitation.organization
        @user = users(:tobias)
        session[:user_id] = @user.id
      end

      describe 'successful invitation' do
        it 'will invite the user to the organizations team' do
          stub_json_request(:get, github_url("/organizations/#{@organization.github_id}"),
                        { login: @organization.title,
                          id: @organization.github_id } )

          stub_json_request(:get, github_url("/user/memberships/orgs/#{@organization.title}"),
                            { state: 'active',
                              role:  'admin' })

          stub_json_request(:get, github_url('/user'),
                            { login: @user.login })

          memberships_url = github_url("/teams/#{@invitation.team_id}/memberships/#{@user.login}")
          stub_json_request(:put, memberships_url,
                            { url: memberships_url,
                              state: 'pending' })

          get :show, { id: @invitation.key }

          assert 'Success!', @response.body
          assert 200,       @response.status
        end
      end

      describe 'unsuccessful invitation' do
        # it 'will fail if the invitation that does not exist' do
        #   get :show, { id: 'foobar' }
        #
        #   assert 'Invitation does not exist :-(', @response.body
        #   assert 503, @response.status
        # end

        # it 'will fail if classroom does not have a vaild admin' do
        #   stub_json_request(:get, github_url("/organizations/#{@organization.github_id}"),
        #                     { login: @organization.title,
        #                       id: @organization.github_id } )
        #
        #   stub_json_request(:get, github_url("/user/memberships/orgs/#{@organization.title}"),
        #                     { state: 'active',
        #                       role:  'member' })
        #
        #   assert 'Failed :-(', @response.body
        #   assert 503, @response.status
        # end
      end
    end
  end
end
