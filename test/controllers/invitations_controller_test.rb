require 'test_helper'

class InvitationsControllerTest < ActionController::TestCase
  before do
    @controller = InvitationsController.new
    @org_login  = 'testorg'
  end

  describe '#create' do
    it 'will create the invitation if one does not exist' do
      @user             = create(:user_with_organizations)
      session[:user_id] = @user.id

      @organization        = @user.organizations.first
      new_invitation_attrs = attributes_for(:invitation)

      stub_json_request(:get, github_url("/teams/#{new_invitation_attrs[:team_id]}"), nil)
      stub_json_request(:post,
                        github_url("/organizations/#{@organization.github_id}/teams"),
                        { name: new_invitation_attrs[:title], permission: 'push'}.to_json,
                        { id: new_invitation_attrs[:team_id], name: new_invitation_attrs[:title] })


      assert_difference 'Invitation.count' do
        post :create,
          organization_id: @organization.id,
          invitation:  { title:   new_invitation_attrs[:title],
                         team_id: new_invitation_attrs[:team_id] }
      end
    end

    it 'will override the organizations invitation if it already exists' do
      @invitation   = create(:invitation)
      @organization = @invitation.organization

      @user             = @invitation.user
      session[:user_id] = @user.id

      new_invitation_attrs = attributes_for(:invitation)

      stub_json_request(:get, github_url("/teams/#{new_invitation_attrs[:team_id]}"), nil)
      stub_json_request(:post,
                        github_url("/organizations/#{@organization.github_id}/teams"),
                        { name: new_invitation_attrs[:title], permission: 'push'}.to_json,
                        { id: new_invitation_attrs[:team_id], name: new_invitation_attrs[:title] })

      assert_no_difference 'Invitation.count' do
        post :create,
          organization_id: @organization.id,
          invitation:  { title:   new_invitation_attrs[:title],
                         team_id: new_invitation_attrs[:team_id] }
      end
    end
  end

  describe '#show' do
    before do
      @invitation = create(:invitation)
    end

    describe 'unathenticated request' do
      it 'will redirect the new user to sign in with GitHub' do
        get :show, { id: @invitation.key }
        assert_redirected_to login_path
      end
    end

    describe 'authenticated request' do
      before do
        @user             = create(:user)
        session[:user_id] = @user.id

        @invitation       = create(:invitation)
        @organization     = @invitation.organization
      end

      describe 'successful invitation' do
        it 'will invite the user to the organizations team' do
          user_login = 'user'

          stub_json_request(:get,
                            github_url("/organizations/#{@organization.github_id}"),
                            { login: @organization.title, id: @organization.github_id } )

          stub_json_request(:get,
                            github_url("/user/memberships/orgs/#{@org_login}"),
                            { state: 'active', role: 'admin' })

          stub_json_request(:get,
                            github_url('/user'),
                            { login: user_login })

          memberships_url = github_url("/teams/#{@invitation.team_id}/memberships/#{user_login}")
          stub_json_request(:put,
                            memberships_url,
                            { url: memberships_url, state: 'pending' })

          get :show, { id: @invitation.key }

          assert 'Success!', @response.body
          assert 200,        @response.status
        end
      end

      describe 'unsuccessful invitation' do
        it 'will raise ActiveRecord::RecordNotFound if the invitation does not exist' do
          assert_raises(ActiveRecord::RecordNotFound) do
            get :show, { id: 'foobar' }
          end
        end
      end
    end
  end

  describe '#destroy' do
    before do
      invitation        = create(:invitation)
      session[:user_id] = invitation.user_id
      @organization     = invitation.organization
    end

    it 'deletes the invitation' do
      assert_difference 'Invitation.count', -1 do
        delete :destroy, organization_id: @organization.id
      end
    end
  end
end
