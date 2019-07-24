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
    context "with flipper on" do
      before(:each) do
        GitHubClassroom.flipper[:google_classroom_roster_import].enable
      end

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

          get :index, params: {
            id: organization.slug
          }
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

      after(:each) do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
      end
    end

    context "with flipper off" do
      before do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
        get :index, params: {
          id: organization.slug
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#create", :vcr do
    context "with flipper on" do
      before(:each) do
        GitHubClassroom.flipper[:google_classroom_roster_import].enable
      end

      context "when the user is authorized" do
        before do
          # Stub google authentication again
          client = Signet::OAuth2::Client.new
          allow_any_instance_of(ApplicationController)
            .to receive(:user_google_classroom_credentials)
            .and_return(client)

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

      after(:each) do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
      end
    end

    context "with flipper off" do
      before do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
        post :create, params: {
          id: organization.slug,
          course_id: 6464
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#search", :vcr do
    context "with flipper on" do
      before(:each) do
        GitHubClassroom.flipper[:google_classroom_roster_import].enable
      end

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
          expect(response).to have_http_status(:success)
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

      after(:each) do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
      end
    end

    context "with flipper off" do
      before do
        GitHubClassroom.flipper[:google_classroom_roster_import].disable
        get :search, params: {
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
