# frozen_string_literal: true

require "rails_helper"

RSpec.describe PagesController, type: :controller do
  describe "GET #home" do
    it "returns success" do
      get :home
      expect(response).to have_http_status(200)
    end

    it "redirects to the dashboard if the user is already logged in" do
      sign_in_as(create(:user))

      get :home
      expect(response).to redirect_to(organizations_path)
    end

    context "assigns correct value to @repo_count" do
      it "if AssignmentRepo and GroupAssignmentRepo present" do
        allow(AssignmentRepo).to receive_message_chain("last.id").and_return(1)
        allow(GroupAssignmentRepo).to receive_message_chain("last.id").and_return(1)
        get :home
        expect(assigns(:repo_count)).to eq(2)
      end

      it "if AssignmentRepo present and GroupAssignmentRepo not present" do
        allow(AssignmentRepo).to receive_message_chain("last.id").and_return(1)
        get :home
        expect(assigns(:repo_count)).to eq(1)
      end

      it "if AssignmentRepo not present and GroupAssignmentRepo present" do
        allow(GroupAssignmentRepo).to receive_message_chain("last.id").and_return(1)
        get :home
        expect(assigns(:repo_count)).to eq(1)
      end

      it "if both AssignmentRepo and GroupAssignmentRepo not present" do
        allow(AssignmentRepo).to receive(:last).and_return(nil)
        allow(GroupAssignmentRepo).to receive(:last).and_return(nil)
        get :home
        expect(assigns(:repo_count)).to eq(0)
      end
    end

    context "assigns correct value to @teacher_count" do
      it "if no users present" do
        allow(User).to receive(:last).and_return(nil)
        get :home
        expect(assigns(:teacher_count)).to eq(0)
      end

      it "if user present" do
        allow(User).to receive_message_chain("last.id").and_return(1)
        get :home
        expect(assigns(:teacher_count)).to eq(1)
      end
    end
  end

  describe "GET #help" do
    it "returns success" do
      expected_pages = [
        "create-group-assignments",
        "probot-settings",
        "upgrade-your-organization",
        "using-template-repos-for-assignments",
        "creating-an-individual-assignment",
        "connect-to-lms",
        "generate-lms-credentials",
        "setup-generic-lms",
        "setup-canvas",
        "setup-moodle"
      ]
      expected_pages.each do |help_page|
        get :help, params: { article_name: help_page }
        expect(response).to have_http_status(200)
      end
    end
  end
end
