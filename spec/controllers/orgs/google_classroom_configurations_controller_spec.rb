# frozen_string_literal: true

require "rails_helper"
require "signet/oauth_2/client"
require "google/apis/classroom_v1"

RSpec.describe Orgs::GoogleClassroomConfigurationsController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }

  before do
    sign_in_as(user)
    GoogleAPI = Google::Apis::ClassroomV1
  end

  describe "#index", :vcr do
    context "when the user is authorized" do
      before do
        client = Signet::OAuth2::Client.new
        allow_any_instance_of(ApplicationController)
          .to receive(:user_google_classroom_credentials)
          .and_return(client)

        response = GoogleAPI::ListCoursesResponse.new
        allow_any_instance_of(GoogleAPI::ClassroomService)
          .to receive(:list_courses)
          .and_return(response)
      end

      it "succeeds" do
        get :index, params: {
          id: organization.slug
        }

        expect(response).to have_http_status(:success)
      end

      context "there is a LTI configuration" do
        before(:each) do
          @lti_configuration = create(:lti_configuration,
            organization: organization,
            consumer_key: "hi",
            shared_secret: "hi")

          get :index, params: {
            id: organization.slug
          }
        end

        it "flashes error message" do
          lms_name = @lti_configuration.lms_name(default_name: "a learning management system")
          expect(flash[:alert]).to eq("This classroom is already connected to #{lms_name}. "\
            "Please disconnect from #{lms_name} before connecting to Google Classroom.")
        end

        it "redirects to settings page" do
          expect(response).to redirect_to(edit_organization_path(organization))
        end

        after(:each) do
          organization.lti_configuration = nil
          organization.save!
          organization.reload
        end
      end

      context "there is a roster" do
        before(:each) do
          organization.roster = create(:roster)
          organization.save!
          organization.reload

          get :index, params: {
            id: organization.slug
          }
        end

        it "flashes error message" do
          message = "We are unable to link your classroom organization to Google Classroom "\
            "because a roster already exists. Please delete your current roster and try again."
          expect(flash[:alert]).to eq(message)
        end

        it "redirects to settings page" do
          expect(response).to redirect_to(edit_organization_path(organization))
        end

        after(:each) do
          organization.roster = nil
          organization.save!
          organization.reload
        end
      end

      context "when there is an error fetching classes" do
        before do
          allow_any_instance_of(GoogleAPI::ClassroomService)
            .to receive(:list_courses)
            .and_raise(Google::Apis::ServerError.new("boom"))

          patch :index, params: {
            id: organization.slug
          }
        end

        it "sets error message" do
          expect(flash[:error]).to eq("Failed to fetch classroom from Google Classroom. Please try again.")
        end
      end
    end

    context "when user is not authorized" do
      before do
        # Stub google authentication again
        allow_any_instance_of(ApplicationController)
          .to receive(:user_google_classroom_credentials)
          .and_return(nil)

        get :index, params: {
          id: organization.slug
        }
      end

      it "redirects to authorization url" do
        expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
      end
    end
  end

  describe "#create", :vcr do
    context "when the user is authorized" do
      before(:each) do
        # Stub google authentication again
        client = Signet::OAuth2::Client.new
        allow_any_instance_of(ApplicationController)
          .to receive(:user_google_classroom_credentials)
          .and_return(client)
      end

      it "creates a statsd event" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("google_classroom.create")

        post :create, params: {
          id: organization.slug,
          course_id: 6464
        }
      end

      context "creates configuration" do
        before do
          post :create, params: {
            id: organization.slug,
            course_id: 6464
          }
        end

        it "suceeds" do
          expect(Organization.first.google_course_id).to eq("6464")
          expect(flash[:success]).to eq("Google Classroom integration was succesfully configured.")
        end
      end

      context "there is a LTI configuration" do
        before(:each) do
          @lti_configuration = create(:lti_configuration,
            organization: organization,
            consumer_key: "hi",
            shared_secret: "hi")

          post :create, params: {
            id: organization.slug,
            course_id: 6464
          }
        end

        it "flashes error message" do
          lms_name = @lti_configuration.lms_name(default_name: "a learning management system")
          expect(flash[:alert]).to eq("This classroom is already connected to #{lms_name}. "\
            "Please disconnect from #{lms_name} before connecting to Google Classroom.")
        end

        it "redirects to settings page" do
          expect(response).to redirect_to(edit_organization_path(organization))
        end

        after(:each) do
          organization.lti_configuration = nil
          organization.save!
          organization.reload
        end
      end

      context "there is a roster" do
        before(:each) do
          organization.roster = create(:roster)
          organization.save!
          organization.reload

          post :create, params: {
            id: organization.slug,
            course_id: 6464
          }
        end

        it "flashes error message" do
          message = "We are unable to link your classroom organization to Google Classroom "\
            "because a roster already exists. Please delete your current roster and try again."
          expect(flash[:alert]).to eq(message)
        end

        it "redirects to settings page" do
          expect(response).to redirect_to(edit_organization_path(organization))
        end

        after(:each) do
          organization.roster = nil
          organization.save!
          organization.reload
        end
      end
    end

    context "when user is not authorized" do
      before do
        # Stub google authentication again
        allow_any_instance_of(ApplicationController)
          .to receive(:user_google_classroom_credentials)
          .and_return(nil)

        post :create, params: {
          id: organization.slug,
          course_id: 6464
        }
      end

      it "redirects to authorization url" do
        expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
      end
    end
  end

  describe "#search", :vcr do
    context "when the user is authorized" do
      before do
        # Stub google authentication again
        client = Signet::OAuth2::Client.new
        allow_any_instance_of(ApplicationController)
          .to receive(:user_google_classroom_credentials)
          .and_return(client)

        response = GoogleAPI::ListCoursesResponse.new
        allow_any_instance_of(GoogleAPI::ClassroomService)
          .to receive(:list_courses)
          .and_return(response)

        get :search, params: {
          id: organization.slug,
          query: ""
        }
      end

      it "succeeds" do
        expect(response).to have_http_status(200)
      end
    end

    context "when user is not authorized with google" do
      before do
        allow_any_instance_of(ApplicationController)
          .to receive(:user_google_classroom_credentials)
          .and_return(nil)

        get :search, params: {
          id: organization.slug,
          query: ""
        }
      end

      it "redirects to authorization url" do
        expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
      end
    end
  end

  describe "#destroy", :vcr do
    context "deletes google classroom" do
      before do
        organization.update(google_course_id: "3333")
        delete :destroy, params: {
          id: organization.slug
        }
        organization.reload
      end

      it "succeeds" do
        expect(organization.google_course_id).to be_nil
      end

      it "redirects or organization page" do
        expect(response).to redirect_to(organization_path(organization))
      end
    end

    context "sends statsd" do
      before do
        organization.update(google_course_id: "3333")
      end

      it "succeeds" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("google_classroom.destroy")

        delete :destroy, params: {
          id: organization.slug
        }
      end
    end
  end
end
