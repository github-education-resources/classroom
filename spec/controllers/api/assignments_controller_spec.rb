# # frozen_string_literal: true

# require "rails_helper"

# RSpec.describe API::AssignmentsController, type: :controller do
#   let(:organization)      { classroom_org                                   }
#   let(:user)              { classroom_teacher                               }
#   let(:assignment)        { create(:assignment, organization: organization) }
#   let(:group_assignment)  { create(:group_assignment, organization: organization) }

#   before do
#     sign_in_as(user)
#   end

#   describe "GET #index", :vcr do

#     context "individual assignment" do
#       before do
#         get :index, params: {organization_id: organization.slug, type: "individual"}
#       end

#       it "returns success" do
#         expect(response).to have_http_status(:success)
#       end

#       it "returns all of user's indiviudal assignments" do
#         expect(json.length).to eql(1)
#       end
#     end

#   end
# end