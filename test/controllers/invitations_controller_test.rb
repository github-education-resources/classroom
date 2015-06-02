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

      stub_github_team(new_invitation_attrs[:team_id], nil)

      stub_create_github_team(@organization.github_id,
                              { name: new_invitation_attrs[:title], permission: 'push'},
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

      stub_github_team(new_invitation_attrs[:team_id], nil)

      stub_create_github_team(@organization.github_id,
                              { name: new_invitation_attrs[:title], permission: 'push'},
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

          stub_github_organization(@organization.github_id, { login: @organization.title, id: @organization.github_id })

          stub_users_github_organization_membership(user_login, { login: @organization.title, id: @organization.github_id })

          stub_github_user(nil, { login: user_login })

          stub_add_team_membership(@invitation.team_id, user_login, {  state: 'pending' })

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
      @invitation        = create(:invitation)
      @organization     = @invitation.organization
      session[:user_id] = @invitation.user_id
    end

    it 'deletes the invitation' do
      assert_difference 'Invitation.count', -1 do
        delete :destroy, organization_id: @organization.id, id: @invitation.id
      end
    end
  end
end
