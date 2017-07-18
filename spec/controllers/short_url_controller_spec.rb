# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShortUrlController, type: :controller do
  describe "unauthenticated request" do
    describe "GET #accept_assignment", :vcr do
      let(:invitation) { create(:assignment_invitation) }

      context "key is invalid" do
        before do
          get :assignment_invitation, params: { short_key: "WRONG" }
        end

        it "responds with a 404" do
          expect(response.status).to eq(404)
        end
      end

      context "key is valid" do
        before do
          key = invitation.short_key

          get :assignment_invitation, params: { short_key: key }
        end

        it "responds with a 302" do
          expect(response).to have_http_status(302)
        end

        it "redirects to the accept assignment page" do
          expect(response).to redirect_to "/assignment-invitations/#{invitation.key}"
        end
      end
    end

    describe "GET #accept_group_assignment", :vcr do
      let(:invitation) { create(:group_assignment_invitation) }

      context "key is invalid" do
        before do
          get :group_assignment_invitation, params: { short_key: "WRONG" }
        end

        it "responds with a 404" do
          expect(response.status).to eq(404)
        end
      end

      context "key is valid" do
        before do
          key = invitation.short_key

          get :group_assignment_invitation, params: { short_key: key }
        end

        it "responds with a 302" do
          expect(response).to have_http_status(302)
        end

        it "redirects to the accept group assignment page" do
          expect(response).to redirect_to "/group-assignment-invitations/#{invitation.key}"
        end
      end
    end
  end
end
