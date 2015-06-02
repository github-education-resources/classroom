require 'test_helper'

class AssignmentsControllerTest < ActionController::TestCase
  before do
    @controller       = AssignmentsController.new
    @user             = create(:user_with_organizations)
    session[:user_id] = @user.id
  end

  describe '#new' do
    before do
      @organization = @user.organizations.first
    end

    it 'returns success with an organization and a new assignment' do
      get :new, organization_id: @organization.id
      assert_response :success
    end

    it 'has an organization' do
      get :new, organization_id: @organization.id
      assert_not_nil(:organization)
    end

    it 'has a new assignment' do
      get :new, organization_id: @organization.id
      assert_not_nil(:assignment)
    end
  end

  describe '#create' do
    before do
      @organization = @user.organizations.first
    end

    it 'will create a new valid assignment' do
      assignment = build(:assignment)

      assert_difference 'Assignment.count' do
        post :create,
          organization_id: @organization.id,
          assignment: { title: assignment.title }
      end
    end
  end

  describe '#show' do
    before do
      @assignment   = create(:assignment)
      @organization = @assignment.organization
    end

    it 'returns success and sets its assignment and organization' do
      get :show, organization_id: @organization.id, id: @assignment.id

      assert_response :success
      assert_not_nil assigns(:assignment)
      assert_not_nil assigns(:organization)
    end
  end

  describe '#edit' do
    before do
      @assignment   = create(:assignment)
      @organization = @assignment.organization
    end

    it 'returns success and sets the assignment and organization' do
      get :edit, organization_id: @organization.id, id: @assignment.id

      assert_response :success
      assert_not_nil assigns(:assignment)
      assert_not_nil assigns(:organization)
    end
  end

  describe '#update' do
    before do
      @assignment   = create(:assignment)
      @organization = @assignment.organization
    end

    it 'returns success and updates the assignment' do
      new_title = 'Updated Assignment'

      put :update, organization_id: @organization, id: @assignment.id, assignment: { title: new_title }
      assert new_title, @assignment.title
    end
  end

  describe '#destroy' do
    before do
      @assignment   = create(:assignment)
      @organization = @assignment.organization
    end

    it 'deletes the assignment' do
      assert_difference 'Assignment.count', -1 do
        delete :destroy, organization_id: @organization.id, id: @assignment.id
      end
    end

    it 'redirects back to the organization' do
      delete :destroy, organization_id: @organization.id, id: @assignment.id
      assert_redirected_to organization_path(@organization)
    end
  end
end
