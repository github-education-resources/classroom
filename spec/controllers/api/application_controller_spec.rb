# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::ApplicationController, type: :controller do
  controller do
    def index
      render json: {}, status: :ok
    end
  end

  let(:user) { classroom_teacher }

  describe "token authentication tests" do
    context "access token is present", :vcr do
      context "valid access token" do
        context "user id is missing" do
          before do
            @access_token = MessageVerifier.encode(random_value: 1)
          end

          it "renders forbidden" do
            get :index, params: { access_token: @access_token }
            expect(response).to have_http_status(:forbidden)
          end
        end

        context "user id is present" do
          before do
            @access_token = MessageVerifier.encode(user_id: user.id)
          end

          it "renders ok" do
            get :index, params: { access_token: @access_token }
            expect(response).to have_http_status(:ok)
          end
        end
      end

      context "invalid access token" do
        context "token is expired" do
          before do
            @access_token = MessageVerifier.encode({ user_id: user.id }, 30.seconds.ago)
          end

          it "renders forbidden" do
            get :index, params: { access_token: @access_token }
            expect(response).to have_http_status(:forbidden)
          end
        end

        context "token is malformed" do
          before do
            @access_token = "malformed token"
          end

          it "renders forbidden" do
            get :index, params: { access_token: @access_token }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end

    context "access token is not present" do
      it "renders forbidden" do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
