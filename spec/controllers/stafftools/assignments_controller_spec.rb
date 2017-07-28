# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::AssignmentsController, type: :controller do
  let(:user)       { classroom_teacher }
  let(:assignment) { create(:assignment) }

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #show", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :show, params: { id: assignment.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: assignment.id }
      end

      it "succeeds" do
        expect(response).to have_http_status(:success)
      end

      it "sets the Assignment" do
        expect(assigns(:assignment).id).to eq(assignment.id)
      end
    end
  end
end
