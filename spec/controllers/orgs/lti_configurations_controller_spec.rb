# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orgs::LtiConfigurationsController, type: :controller do
  let(:organization) { classroom_org }
  let(:user)         { classroom_teacher }

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #new", :vcr do
    before(:each) do
      get :new, params: { id: organization.slug }
    end

    it "returns success status" do
      expect(response).to have_http_status(200)
    end

    it "renders new template" do
      expect(response).to render_template(:new)
    end
  end

  describe "GET #info", :vcr do
    before(:each) do
      get :info, params: { id: organization.slug }
    end

    it "returns success status" do
      expect(response).to have_http_status(200)
    end

    it "renders new template" do
      expect(response).to render_template(:info)
    end
  end

  describe "GET #show", :vcr do
    context "with lti_configuration present" do
      before(:each) do
        create(:lti_configuration, organization: organization)
        get :show, params: { id: organization.slug }
      end

      it "returns success status" do
        expect(response).to have_http_status(200)
      end

      it "renders show template" do
        expect(response).to render_template(:show)
      end
    end

    context "with no existing lti_configuration" do
      it "redirects to new" do
        get :show, params: { id: organization.slug }
        expect(response).to redirect_to(info_lti_configuration_path(organization))
      end
    end
  end

  describe "POST #create", :vcr do
    it "sends statsd" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("lti_configuration.create")
      post :create, params: { id: organization.slug, lti_configuration: { lms_type: :other } }
    end

    it "creates lti_configuration if lms_type is set" do
      post :create, params: { id: organization.slug, lti_configuration: { lms_type: :other } }
      expect(organization.lti_configuration).to_not be_nil
      expect(response).to redirect_to(lti_configuration_path(organization))
    end

    it "redirects to :new if lms_type is unset" do
      post :create, params: { id: organization.slug }
      expect(organization.lti_configuration).to be_nil
      expect(response).to redirect_to(new_lti_configuration_path(organization))
    end

    context "with existing google classroom" do
      before do
        organization.update_attributes(google_course_id: "1234")
      end

      it "alerts user about existing configuration" do
        get :create, params: { id: organization.slug }
        expect(response).to redirect_to(edit_organization_path(organization))
        expect(flash[:alert]).to eq(
          "This classroom is already connected to Google Classroom. Please disconnect from Google Classroom "\
          "before connecting to another learning management system."
        )
      end
    end

    context "with an existing roster" do
      before do
        organization.roster = create(:roster)
        organization.save!
        organization.reload
      end

      it "alerts user that there is an existing roster" do
        post :create, params: { id: organization.slug }
        expect(response).to redirect_to(edit_organization_path(organization))
        expect(flash[:alert]).to eq(
          "We are unable to link your classroom organization to a learning management system "\
          "because a roster already exists. Please delete your current roster and try again."
        )
      end
    end
  end

  describe "DELETE #destroy", :vcr do
    context "with lti configuration present" do
      before(:each) do
        create(:lti_configuration, organization: organization)
        get :show, params: { id: organization.slug }
      end

      it "sends statsd" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("lti_configuration.destroy")
        delete :destroy, params: { id: organization.slug }
      end

      it "deletes lti_configuration" do
        delete :destroy, params: { id: organization.slug }
        organization.reload
        expect(organization.lti_configuration).to be_nil
        expect(response).to redirect_to(edit_organization_path(id: organization))
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "GET #autoconfigure", :vcr do
    context "with existing lti_configuration" do
      before(:each) do
        create(:lti_configuration, organization: organization)
      end

      context "with autoconfiguration enabled" do
        before(:each) { LtiConfiguration.any_instance.stub(:supports_autoconfiguration?).and_return(true) }

        it "returns an xml configuration" do
          get :autoconfigure, params: { id: organization.slug }
          expect(response).to have_http_status(200)
          expect(response.content_type).to eq "application/xml"
        end
      end

      context "with autoconfiguration disabled" do
        before(:each) { LtiConfiguration.any_instance.stub(:supports_autoconfiguration?).and_return(false) }

        it "does not return an xml configuration" do
          get :autoconfigure, params: { id: organization.slug }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "with no existing lti_configuration" do
      it "does not generate an xml configuration" do
        patch :autoconfigure, params: { id: organization.slug }
        expect(response).to redirect_to(info_lti_configuration_path(organization))
        expect(organization.lti_configuration).to be_nil
      end
    end
  end

  describe "GET #complete", :vcr do
    context "with existing lti_configuration" do
      before(:each) do
        create(:lti_configuration, organization: organization)
      end

      context "with user who is an instructor" do
        it "returns success page" do
          get :complete, params: { id: organization.slug }
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
