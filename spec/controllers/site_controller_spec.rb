# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteController, type: :controller do
  let(:user) { classroom_teacher }

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #boom_town", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :boom_town
        expect(response.status).to eq(404)
      end
    end

    context "as site admin" do
      before do
        user.update_attributes(site_admin: true)
      end

      it "raises BOOM" do
        expect do
          get :boom_town
        end.to raise_error(StandardError, "BOOM")
      end
    end
  end

  describe "GET #boom_sidekiq", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :boom_sidekiq
        expect(response.status).to eq(404)
      end
    end

    context "as a site admin" do
      before do
        user.update_attributes(site_admin: true)
      end

      it "queues a BoomJob" do
        expect do
          get :boom_sidekiq
        end.to enqueue_job(BoomJob)
      end
    end
  end
end
