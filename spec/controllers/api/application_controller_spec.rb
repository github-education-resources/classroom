# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::ApplicationController, type: :controller do
  controller do
    def index
      render json: {}, status: :ok
    end
  end

  context "flipper is enabled for the user" do
    before do
      GitHubClassroom.flipper[:download_repositories].enable
    end

    describe "API Application Controller Authentication Tests", :vcr do
      context "user has adequate scopes" do
        subject { classroom_teacher }

        context "user is logged in" do
          before(:each) do
            sign_in_as(subject)
          end

          context "access token is valid" do
            it "renders action" do
              get :index
              expect(response).to have_http_status(:ok)
            end
          end

          context "access token is invalid" do
            before do
              User.any_instance.stub(:authorized_access_token?).and_return(false)
            end

            it "returns forbidden" do
              get :index
              expect(response).to have_http_status(:forbidden)
            end
          end
        end

        context "user is not logged in" do
          it "returns 404" do
            get :index
            expect(response.status).to eq(404)
          end
        end
      end

      context "user does not have adequate scopes" do
        subject { classroom_student }

        before do
          sign_in_as(classroom_student)
        end

        it "returns forbidden" do
          get :index
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    after do
      GitHubClassroom.flipper[:download_repositories].disable
    end
  end

  context "flipper is not enabled for the user" do
    it "returns a 404" do
      get :index
      expect(response.status).to eq(404)
    end
  end
end
