# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentsController, type: :controller do
  let(:organization)          { classroom_org                                         }
  let(:user)                  { classroom_teacher                                     }
  
  before do
    sign_in_as(user)

    @assignment = create(:assignment, organization: organization)
    @assignment_json = AssignmentSerializer.new(@assignment).to_json
  end

  describe "GET #index", :vcr do
    before do
      get :index, params: {organization_id: organization.slug}
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "returns only one assignment" do
      expect(json.length).to eql(1)
    end

    it "returns serialized versions of indivdual assignment" do
      expect(json.first.to_json).to eq(@assignment_json)
    end

  end

  describe "GET #show", :vcr do
    before do
      get :show, params: {organization_id: organization.slug, id: @assignment.slug}
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "returns serialized version of individual assignment" do
      expect(json.to_json).to eq(@assignment_json)
    end
  end
end
