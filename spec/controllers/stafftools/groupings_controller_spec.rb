# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::GroupingsController, type: :controller do
  let(:user)     { classroom_teacher }
  let(:grouping) { create(:grouping) }

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #show", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :show, params: { id: grouping.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: grouping.id }
      end

      it "succeeds" do
        expect(response).to have_http_status(:success)
      end

      it "sets the Grouping" do
        expect(assigns(:grouping).id).to eq(grouping.id)
      end
    end
  end
end
