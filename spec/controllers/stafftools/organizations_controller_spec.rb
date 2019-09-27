# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::OrganizationsController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }
  let(:organization_webhook) do
    organization_webhook = create(
      :organization_webhook,
      github_organization_id: classroom_org.github_id
    )
    classroom_org.update(organization_webhook: organization_webhook)
    organization_webhook
  end

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #show", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :show, params: { id: organization.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        organization_webhook
        user.update_attributes(site_admin: true)
        get :show, params: { id: organization.id }
      end

      it "succeeds" do
        expect(response).to have_http_status(200)
      end

      it "sets the organization" do
        expect(assigns(:organization).id).to eq(organization.id)
      end

      it "sets the organization_webhook" do
        expect(assigns(:organization_webhook).id).to eq(organization_webhook.id)
      end
    end
  end

  describe "POST #ensure_webhook_is_active", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        post :ensure_webhook_is_active, params: { id: organization.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        organization_webhook
        user.update_attributes(site_admin: true)
      end

      context "ensure_webhook_is_active returns true" do
        before do
          expect_any_instance_of(OrganizationWebhook).to receive(:ensure_webhook_is_active!).and_return(true)
          post :ensure_webhook_is_active, params: { id: organization.id }
        end

        it "redirects" do
          expect(response).to have_http_status(:redirect)
        end

        it "flashes a success" do
          expect(flash[:success]).to be_present
        end
      end

      context "ensure_webhook_is_active raises an error" do
        before do
          expect_any_instance_of(OrganizationWebhook)
            .to receive(:ensure_webhook_is_active!)
            .and_raise(OrganizationWebhook::NoValidTokenError)
          post :ensure_webhook_is_active, params: { id: organization.id }
        end

        it "redirects" do
          expect(response).to have_http_status(:redirect)
        end

        it "flashes a error" do
          expect(flash[:error]).to be_present
        end
      end
    end
  end

  describe "DELETE #remove_user", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        delete :remove_user, params: { id: organization.id, user_id: user.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
      end

      context "when user does not own any assignments" do
        before do
          delete :remove_user, params: { id: organization.id, user_id: user.id }
        end

        it "deletes user from the Organization" do
          expect(organization.users.reload.include?(user)).to be_falsey
        end

        it "displays a helpful flash success message" do
          expect(flash[:success]).to eq("The user has been removed from the classroom")
        end

        it "redirects to stafftools organization path" do
          expect(response).to redirect_to(stafftools_organization_path(organization.id))
        end
      end

      context "when user owns at least one assignment" do
        before do
          create(:assignment, creator: user, organization: organization, title: "Title")
          delete :remove_user, params: { id: organization.id, user_id: user.id }
        end

        it "does not delete the user from the Organization" do
          expect(organization.users.reload.include?(user)).to be_truthy
        end

        it "displays an error flash message" do
          expect(flash[:error]).to eq("This user owns at least one assignment and cannot be deleted")
        end

        it "redirects to stafftools organization path" do
          expect(response).to redirect_to(stafftools_organization_path(organization.id))
        end
      end
    end
  end
end
