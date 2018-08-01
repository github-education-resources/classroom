# frozen_string_literal: true

require "rails_helper"

RSpec.describe OauthController, type: :controller do
  let(:user)          { classroom_teacher }

  context "flipper is enabled" do
    before do
      sign_in_as(user)
      GitHubClassroom.flipper[:download_repositories].enable
    end

    describe "GET #authorize", :vcr do
      context "redirect url param is not present" do
        it "renders 404" do
          get :authorize
          expect(response).to have_http_status(:not_found)
        end
      end

      context "redirect url param is present" do
        before(:each) do
          Timecop.freeze
          get :authorize, params: { redirect_uri: "http://redirect-url-test.com" }
        end

        it "redirects to redirect url" do
          expect(redirect_url_without_params).to eql("http://redirect-url-test.com")
        end

        it "generates a code that is invalid in 5 minutes" do
          data = JsonWebToken.decode(redirect_params["code"])
          expect(data[:exp]).to eql(5.minutes.from_now.to_i)
        end

        it "generates a code that has correct user id" do
          data = JsonWebToken.decode(redirect_params["code"])
          expect(data[:user_id]).to eql(user.id)
        end

        after(:each) do
          Timecop.return
        end
      end
    end

    describe "GET #access_token", :vcr do
      before do
        sign_out
      end

      context "code param is present" do
        context "valid code param" do
          before do
            Timecop.freeze
            @code = user.api_token
          end

          it "returns access token that expires in 24 hours" do
            get :access_token, params: { code: @code }
            access_token = json["access_token"]
            data = JsonWebToken.decode(access_token)
            expect(data[:exp]).to eql(24.hours.from_now.to_i)
          end

          after do
            Timecop.return
          end
        end

        context "invalid code param" do
          before do
            @code = "invalid code"
          end

          it "returns not found" do
            get :access_token, params: { code: @code }

            expect(response).to have_http_status(:not_found)
          end
        end
      end

      context "code param is not present" do
        it "renders 404" do
          get :access_token
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    after do
      GitHubClassroom.flipper[:download_repositories].disable
    end
  end

  context "flipper is not enabled" do
    it "renders not found for authorize" do
      get :authorize
      expect(response).to have_http_status(:not_found)
    end

    it "renders not found for access_token" do
      get :access_token
      expect(response).to have_http_status(:not_found)
    end
  end

  private

  def redirect_params
    Rack::Utils.parse_query(URI.parse(response.location).query)
  end

  def redirect_url_without_params
    url = URI.parse(response.location)
    "#{url.scheme}://#{url.host}"
  end
end
