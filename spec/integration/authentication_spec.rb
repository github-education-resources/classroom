# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OAuth scope requirements", type: :request do
  let(:organization) { classroom_org }

  describe "organizations#show", :vcr do
    context "unauthenticated request" do
      it "redirects to sessions#new" do
        get url_for(organization)
        expect(response).to redirect_to(login_path)
      end

      it "sets required scopes in session" do
        get url_for(organization)
        expect(session[:required_scopes])
          .to eq("user:email,repo,delete_repo,admin:org,admin:org_hook")
      end
    end

    context "authenticated request" do
      before(:each) do
        get url_for(organization)
        get response.redirect_url # http://www.example.com/login
        get response.redirect_url # http://www.example.com/auth/github?scope=user%3Aemail%2Crepo%2Cdelete_repo%2Cadmin%3Aorg%2Cadmin%3Aorg_hook
        get response.redirect_url # http://www.example.com/auth/github/callback
      end

      it "renders organizations#show" do
        get response.redirect_url
        expect(response.status).to eq(200)
        expect(response).to render_template("organizations/show")
      end
    end
  end

  describe "sessions#new" do
    before(:each) do
      get url_for(organization)
    end

    it "redirects to omniauth" do
      get response.redirect_url
      url = "/auth/github?scope=user%3Aemail%2Crepo%2Cdelete_repo%2Cadmin%3Aorg%2Cadmin%3Aorg_hook"
      expect(response).to redirect_to(url)
    end
  end

  describe "sessions#failure" do
    it "redirects to the homepage with an error" do
      get "/auth/failure"
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eql("There was a problem authenticating with GitHub, please try again.")
    end
  end

  describe "OAuth dance", :vcr do
    before(:each) do
      get url_for(organization)
      get response.redirect_url # http://www.example.com/login
      get response.redirect_url # http://www.example.com/auth/github?scope=user%3Aemail%2Crepo%2Cdelete_repo%2Cadmin%3Aorg%2Cadmin%3Aorg_hook
    end

    it "redirects back to organizations#show" do
      get response.redirect_url # http://www.example.com/auth/github/callback
      expect(response).to redirect_to(url_for(organization))
    end
  end
end
