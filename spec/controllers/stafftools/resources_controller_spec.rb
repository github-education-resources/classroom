# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::ResourcesController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #index", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :index
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
      end

      context "without URL parameters" do
        before(:each) do
          get :index
        end

        it "returns a success status" do
          expect(response).to have_http_status(:success)
        end

        it "does not have any resources" do
          expect(assigns(:resources)).to be_nil
        end
      end

      context "with URL parameters" do
        before(:each) do
          get :index, params: { query: "1" }
        end

        it "returns a success status" do
          expect(response).to have_http_status(:success)
        end

        it "has a StafftoolsIndex::Query of resources" do
          expect(assigns(:resources)).to_not be_nil
          expect(assigns(:resources)).to be_kind_of(StafftoolsIndex::Query)
        end
      end
    end
  end

  describe "GET #search", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :search
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
      end

      context "without URL parameters" do
        before(:each) do
          get :search
        end

        it "returns a succcess status" do
          expect(response).to have_http_status(:success)
        end

        it "does not have any resources" do
          expect(assigns(:resources)).to be_nil
        end
      end

      context "with URL parameters" do
        before(:each) do
          get :search, params: { query: "1" }
        end

        it "returns a succcess status" do
          expect(response).to have_http_status(:success)
        end

        it "has a StafftoolsIndex::Query of resources" do
          expect(assigns(:resources)).to_not be_nil
          expect(assigns(:resources)).to be_kind_of(StafftoolsIndex::Query)
        end
      end
    end
  end
end
