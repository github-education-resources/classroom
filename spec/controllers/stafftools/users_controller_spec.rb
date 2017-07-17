# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::UsersController, type: :controller do
  let(:user)    { classroom_teacher }
  let(:student) { classroom_student }

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #show", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :show, params: { id: user.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: user.id }
      end

      it "succeeds" do
        expect(response).to have_http_status(:success)
      end

      it "sets the user" do
        expect(assigns(:user).id).to eq(user.id)
      end
    end
  end

  describe "POST #impersonate", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        post :impersonate, params: { id: student.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
      end

      before(:each) do
        post :impersonate, params: { id: student.id }
      end

      it "sets the :impersonated_user_id on the session" do
        expect(session[:impersonated_user_id]).to eql(student.id)
      end

      it "redirects to the root_path" do
        expect(response).to redirect_to("/")
      end
    end
  end

  describe "DELETE #stop_impersonating", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        delete :stop_impersonating, params: { id: student.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
      end

      before(:each) do
        post :impersonate,          params: { id: student.id }
        delete :stop_impersonating, params: { id: student.id }
      end

      it "removes the `:impersonated_user_id` from the session" do
        expect(session[:impersonated_user_id]).to be_nil
      end

      it "redirects back to the `stafftools_root_path`" do
        expect(response).to redirect_to("/stafftools")
      end
    end
  end
end
