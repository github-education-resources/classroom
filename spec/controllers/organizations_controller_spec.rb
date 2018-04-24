# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationsController, type: :controller do
  let(:organization)  { classroom_org     }
  let(:user)          { classroom_teacher }
  let(:student)       { classroom_student }

  before do
    sign_in_as(user)
  end

  describe "GET #index", :vcr do
    context "unauthenticated user" do
      before do
        sign_out
      end

      it "redirects to login_path" do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end

    context "authenticated user with a valid token" do
      it "succeeds" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "sets the users organization" do
        organization # call the record so that it is created

        get :index
        expect(assigns(:organizations).first.id).to eq(organization.id)
      end
    end

    context "user with admin privilege on the organization but not part of the classroom" do
      before(:each) do
        organization.users = []
      end

      it "adds the user to the classroom" do
        get :index

        expect(user.organizations).to include(organization)
      end
    end

    context "user without admin privilege on the organization" do
      before(:each) do
        sign_in_as(student)
      end

      it "does not add the user to the classroom" do
        get :index

        expect(student.organizations).to be_empty
      end
    end

    context "authenticated user with an invalid token" do
      before do
        allow(user).to receive(:ensure_no_token_scope_loss).and_return(true)
        user.update_attributes(token: "1234")
      end

      it "redirects to login_path" do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET #new", :vcr do
    it "returns success status" do
      get :new
      expect(response).to have_http_status(:success)
    end

    it "has a new organization" do
      get :new
      expect(assigns(:organization)).to_not be_nil
    end

    it "has an Kaminari::PaginatableArray of the users GitHub organizations that they are an admin of" do
      get :new
      expect(assigns(:users_github_organizations)).to be_kind_of(Kaminari::PaginatableArray)
    end

    it "will not include any organizations that are already apart of classroom" do
      get :new
      expect(assigns(:users_github_organizations)).not_to include([organization.title, organization.github_id])
    end
  end

  describe "POST #create", :vcr do
    before do
      request.env["HTTP_REFERER"] = "http://classroomtest.com/orgs/new"
    end

    after(:each) do
      organization.destroy!
    end

    it "will fail to add an organization the user is not an admin of" do
      new_organization = build(:organization, github_id: 90)
      new_organization_options = { github_id: new_organization.github_id }

      expect do
        post :create, params: { organization: new_organization_options }
      end.to_not change(Organization, :count)
    end

    it "will not add an organization that already exists" do
      existing_organization_options = { github_id: organization.github_id }
      expect do
        post :create, params: { organization: existing_organization_options }
      end.to_not change(Organization, :count)
    end

    it "will add an organization that the user is admin of on GitHub" do
      organization_params = { github_id: organization.github_id, users: organization.users }
      organization.destroy!

      expect { post :create, params: { organization: organization_params } }.to change(Organization, :count)
    end

    it "will redirect the user to the setup page" do
      organization_params = { github_id: organization.github_id, users: organization.users }
      organization.destroy!

      post :create, params: { organization: organization_params }

      expect(response).to redirect_to(setup_organization_path(Organization.last))
    end
  end

  describe "GET #show", :vcr do
    it "returns success and sets the organization" do
      get :show, params: { id: organization.slug }

      expect(response.status).to eq(200)
      expect(assigns(:current_organization)).to_not be_nil
    end
  end

  describe "GET #edit", :vcr do
    it "returns success and sets the organization" do
      get :edit, params: { id: organization.slug }

      expect(response).to have_http_status(:success)
      expect(assigns(:current_organization)).to_not be_nil
    end
  end

  describe "GET #invitation", :vcr do
    it "returns success and sets the organization" do
      get :invitation, params: { id: organization.slug }

      expect(response).to have_http_status(:success)
      expect(assigns(:current_organization)).to_not be_nil
    end
  end

  describe "PATCH #remove_user", :vcr do
    context "returns 404" do
      it "user is not an org owner" do
        patch :remove_user, params: { id: organization.slug, user_id: student.id }

        expect(response).to have_http_status(404)
      end

      it "user does not exist" do
        patch :remove_user, params: { id: organization.slug, user_id: 105 }

        expect(response).to have_http_status(404)
      end
    end

    context "removes user from classroom" do
      before(:each) do
        teacher = create(:user)
        organization.users << teacher
      end

      it "without assignments" do
        patch :remove_user, params: { id: organization.slug, user_id: @teacher.id }

        expect(response).to redirect_to(settings_invitations_organization_path)
        expect(flash[:success]).to be_present
        expect { organization.users.find(id: @teacher.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "with assignments" do
        assignment = create(:assignment, organization: organization, creator: @teacher)

        patch :remove_user, params: { id: organization.slug, user_id: @teacher.id }

        expect(assignment.reload.creator_id).not_to eq(@teacher.id)
        expect { organization.users.find(id: @teacher.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to redirect_to(settings_invitations_organization_path)
        expect(flash[:success]).to be_present
      end
    end
  end

  describe "GET #show_groupings", :vcr do
    context "flipper is enabled" do
      before do
        GitHubClassroom.flipper[:team_management].enable
      end

      it "returns success and sets the organization" do
        get :show_groupings, params: { id: organization.slug }

        expect(response).to have_http_status(:success)
        expect(assigns(:current_organization)).to_not be_nil
      end

      after do
        GitHubClassroom.flipper[:team_management].disable
      end
    end

    context "flipper is not enabled" do
      it "returns success and sets the organization" do
        get :show_groupings, params: { id: organization.slug }
        expect(response.status).to eq(404)
      end
    end
  end

  describe "PATCH #update", :vcr do
    it "correctly updates the organization" do
      options = { title: "New Title" }
      patch :update, params: { id: organization.slug, organization: options }

      expect(response).to redirect_to(organization_path(Organization.find(organization.id)))
    end
  end

  describe "DELETE #destroy", :vcr do
    it "sets the `deleted_at` column for the organization" do
      organization # call the record so that it is created

      expect { delete :destroy, params: { id: organization.slug } }.to change(Organization, :count)
      expect(Organization.unscoped.find(organization.id).deleted_at).not_to be_nil
    end

    it "calls the DestroyResource background job" do
      delete :destroy, params: { id: organization.slug }

      assert_enqueued_jobs 1 do
        DestroyResourceJob.perform_later(organization)
      end
    end

    it "redirects back to the index page" do
      delete :destroy, params: { id: organization.slug }
      expect(response).to redirect_to(organizations_path)
    end
  end

  describe "GET #invite", :vcr do
    it "returns success and sets the organization" do
      get :invite, params: { id: organization.slug }

      expect(response.status).to eq(200)
      expect(assigns(:current_organization)).to_not be_nil
    end
  end

  describe "GET #setup", :vcr do
    it "returns success and sets the organization" do
      get :setup, params: { id: organization.slug }

      expect(response.status).to eq(200)
      expect(assigns(:current_organization)).to_not be_nil
    end
  end

  describe "PATCH #setup_organization", :vcr do
    before(:each) do
      options = { title: "New Title" }
      patch :update, params: { id: organization.slug, organization: options }
    end

    it "correctly updates the organization" do
      expect(Organization.find(organization.id).title).to eql("New Title")
    end

    it "redirects to the invite page on success" do
      expect(response).to redirect_to(organization_path(Organization.find(organization.id)))
    end
  end
end
