# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentInvitationsController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_student }

  let(:invitation) { create(:assignment_invitation, organization: organization) }

  describe "GET #show", :vcr do
    context "unauthenticated request" do
      it "redirects the new user to sign in with GitHub" do
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(login_path)
      end
    end

    context "authenticated request" do
      before(:each) do
        sign_in_as(user)
      end

      it "will bring you to the page" do
        get :show, params: { id: invitation.key }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH #accept", :vcr do
    let(:result) do
      assignment_repo = create(:assignment_repo, assignment: invitation.assignment, user: user)
      AssignmentRepo::Creator::Result.success(assignment_repo)
    end

    before do
      request.env["HTTP_REFERER"] = "http://classroomtest.com/assignment-invitations/#{invitation.key}"
      sign_in_as(user)
    end

    it "redeems the users invitation" do
      allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for).with(user).and_return(result)

      patch :accept, params: { id: invitation.key }
      expect(user.assignment_repos.count).to eql(1)
    end
  end

  describe "GET #success" do
    let(:assignment) do
      create(:assignment, title: "Learn Clojure", starter_code_repo_id: 1_062_897, organization: organization)
    end

    let(:invitation) { create(:assignment_invitation, assignment: assignment) }

    before(:each) do
      sign_in_as(user)
      result = AssignmentRepo::Creator.perform(assignment: assignment, user: user)
      @assignment_repo = result.assignment_repo
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    context "github repository deleted after accepting a invitation successfully", :vcr do
      before do
        organization.github_client.delete_repository(@assignment_repo.github_repo_id)
        get :success, params: { id: invitation.key }
      end

      it "deletes the old assignment repo" do
        expect { @assignment_repo.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "creates a new assignment repo for the student" do
        expect(AssignmentRepo.last.id).not_to eq(@assignment_repo.id)
      end
    end
  end
end
