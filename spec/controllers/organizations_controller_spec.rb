# frozen_string_literal: true

require "rails_helper"
require "signet/oauth_2/client"
require "google/apis/classroom_v1"

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

      it "logs out user" do
        get :index
        expect(response).to redirect_to(root_path)
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

    context "multiple_classrooms_per_org flag not enabled" do
      before do
        GitHubClassroom.flipper[:multiple_classrooms_per_org].disable
      end

      it "will not add an organization that already exists" do
        existing_organization_options = { github_id: organization.github_id }
        expect do
          post :create, params: { organization: existing_organization_options }
        end.to_not change(Organization, :count)
      end
    end

    context "multiple_classrooms_per_org flag is enabled" do
      before do
        GitHubClassroom.flipper[:multiple_classrooms_per_org].enable
      end

      after do
        GitHubClassroom.flipper[:multiple_classrooms_per_org].disable
      end

      it "will add a classroom on same organization" do
        existing_organization_options = { github_id: organization.github_id }
        expect do
          post :create, params: { organization: existing_organization_options }
        end.to change(Organization, :count)
      end
    end

    it "will fail to add an organization the user is not an admin of" do
      new_organization = build(:organization, github_id: 90)
      new_organization_options = { github_id: new_organization.github_id }

      expect do
        post :create, params: { organization: new_organization_options }
      end.to_not change(Organization, :count)
    end

    it "will add an organization that the user is admin of on GitHub" do
      organization_params = { github_id: organization.github_id, users: organization.users }
      organization.destroy!

      expect { post :create, params: { organization: organization_params } }.to change(Organization, :count)

      expect(Organization.last.github_id).to_not be_nil
      expect(Organization.last.github_global_relay_id).to_not be_nil
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

  describe "search organizations", :vcr do
    before do
      user.organizations = [create(:organization, title: "github_class_300"), organization]
      user.save!
    end

    it "finds an organization" do
      get :search, params: { id: organization.slug, query: "github" }
      expect(response.status).to eq(200)
      expect(assigns(:organizations)).to_not eq([])
    end

    it "finds no organization" do
      get :search, params: { id: organization.slug, query: "testing stuff" }
      expect(response.status).to eq(200)
      expect(assigns(:organizations)).to eq([])
    end

    it "is not case sensitive" do
      get :search, params: { id: organization.slug, query: "GITHUB" }
      expect(response.status).to eq(200)
      expect(assigns(:organizations)).to_not eq([])
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

  describe "GET #select_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "with google classroom flipper enabled" do
      before do
        GitHubClassroom.flipper[:google_classroom_roster_import].enable
      end

      context "when user is authorized with google" do
        before do
          Roster.destroy_all

          # Stub google authentication again
          client = Signet::OAuth2::Client.new
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:user_google_classroom_credentials)
            .and_return(client)

          # Stub list courses response
          response = GoogleAPI::ListCoursesResponse.new
          allow_any_instance_of(GoogleAPI::ClassroomService)
            .to receive(:list_courses)
            .and_return(response)

          get :select_google_classroom, params: {
            id: organization.slug
          }
        end

        it "succeeds" do
          expect(response).to have_http_status(:success)
        end
      end

      context "when there is an existing roster" do
        before do
          organization.roster = create(:roster)
          organization.save!
          organization.reload

          # Stub google authentication again
          client = Signet::OAuth2::Client.new
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:user_google_classroom_credentials)
            .and_return(client)

          # Stub list courses response
          response = GoogleAPI::ListCoursesResponse.new
          allow_any_instance_of(GoogleAPI::ClassroomService)
            .to receive(:list_courses)
            .and_return(response)

          get :select_google_classroom, params: {
            id: organization.slug
          }
        end

        it "alerts user that there is an existing roster" do
          expect(response).to redirect_to(edit_organization_path(organization))
          expect(flash[:alert]).to eq(
            "We are unable to link your classroom organization to Google Classroom "\
            "because a roster already exists. Please delete your current roster and try again."
          )
        end
      end

      context "when there is an existing lti configuration" do
        before do
          # Stub google authentication again
          client = Signet::OAuth2::Client.new
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:user_google_classroom_credentials)
            .and_return(client)

          # Stub list courses response
          response = GoogleAPI::ListCoursesResponse.new
          allow_any_instance_of(GoogleAPI::ClassroomService)
            .to receive(:list_courses)
            .and_return(response)

          create(:lti_configuration,
            organization: organization,
            consumer_key: "hello",
            shared_secret: "hello")

          get :select_google_classroom, params: {
            id: organization.slug
          }
        end

        it "alerts user that there is an exisiting config" do
          expect(flash[:alert]).to eq(
            "A LMS configuration already exists. Please remove configuration before creating a new one."
          )
        end
      end

      context "when user is not authorized with google" do
        before do
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:user_google_classroom_credentials)
            .and_return(nil)

          get :select_google_classroom, params: {
            id: organization.slug
          }
        end

        it "redirects to authorization url" do
          expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
        end
      end

      after do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
      end
    end

    context "with google classroom roster disabled" do
      before do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
        get :search_google_classroom, params: {
          id: organization.slug,
          query: ""
        }
      end

      it "404s" do
        binding.pry
        expect(response).to have_http_status(:not_found)
      end
    end

    after do
      GitHubClassroom.flipper[:student_identifier].disable
    end
  end

  describe "GET #search_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "with google classroom flipper enabled" do
      before do
        GitHubClassroom.flipper[:google_classroom_roster_import].enable
      end

      context "when user is authorized with google" do
        before do
          # Stub google authentication again
          client = Signet::OAuth2::Client.new
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:user_google_classroom_credentials)
            .and_return(client)

          response = GoogleAPI::ListCoursesResponse.new
          allow_any_instance_of(GoogleAPI::ClassroomService)
            .to receive(:list_courses)
            .and_return(response)
        end

        it "renders google classroom collection partial" do
          request = get :search_google_classroom, params: {
            id: organization.slug,
            query: "git"
          }
          expect(request).to render_template(partial: "organizations/_google_classroom_collection")
        end

        context "when there is an existing lti configuration" do
          before do
            create(:lti_configuration,
              organization: organization,
              consumer_key: "hello",
              shared_secret: "hello")
            get :search_google_classroom, params: {
              id: organization.slug,
              query: ""
            }
          end

          it "alerts user that there is an exisiting config" do
            expect(response).to redirect_to(edit_organization_path(organization))
            expect(flash[:alert]).to eq(
              "A LMS configuration already exists. Please remove configuration before creating a new one."
            )
          end
        end
      end

      context "when user is not authorized with google" do
        before do
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:user_google_classroom_credentials)
            .and_return(nil)

          get :search_google_classroom, params: {
            id: organization.slug,
            query: ""
          }
        end

        it "redirects to authorization url" do
          expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
        end
      end

      after do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
      end
    end
  end

  describe "PATCH #unlink_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "with google classroom flipper enabled" do
      before do
        GitHubClassroom.flipper[:google_classroom_roster_import].enable
      end

      context "when user is authorized with google" do
        before do
          # Stub google authentication again
          client = Signet::OAuth2::Client.new
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:user_google_classroom_credentials)
            .and_return(client)

          organization.update_attributes(google_course_id: "1234")

          patch :unlink_google_classroom, params: { id: organization.slug }
        end

        it "removes google course id" do
          expect(organization.reload.google_course_id).to be_nil
        end

        it "flashes success message" do
          message = "Removed link to Google Classroom. No students were removed from your roster."
          expect(flash[:success]).to eq(message)
        end
      end

      context "when user is not authorized with google" do
        before do
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:user_google_classroom_credentials)
            .and_return(nil)

          get :search_google_classroom, params: {
            id: organization.slug,
            query: ""
          }
        end

        it "redirects to authorization url" do
          expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
        end
      end

      after do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
      end
    end

    context "with google classroom identifier disabled" do
      before do
        get :search_google_classroom, params: {
          id: organization.slug,
          query: ""
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
