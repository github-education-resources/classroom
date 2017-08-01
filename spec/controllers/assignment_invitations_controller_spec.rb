# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentInvitationsController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_student }
  let(:config_branch) { ClassroomConfig::CONFIG_BRANCH }

  let(:invitation) { create(:assignment_invitation, organization: organization) }

  let(:unconfigured_repo) { stub_repository("template") }
  let(:configured_repo) { stub_repository("configured-repo") }

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

      context "no roster" do
        it "will bring you to the page" do
          get :show, params: { id: invitation.key }
          expect(response).to have_http_status(:success)
          expect(response).to render_template("assignment_invitations/show")
        end
      end

      context "with a roster" do
        before do
          organization.roster = create(:roster)
          organization.save
        end

        context "with no ignore param" do
          context "when user is on the roster" do
            before do
              RosterEntry.create(roster: organization.roster, user: user, identifier: "a@b.c")
            end

            it "will bring you to the show page" do
              get :show, params: { id: invitation.key }
              expect(response).to render_template("assignment_invitations/show")
            end
          end

          context "when user is not on the roster" do
            it "will bring you to the join_roster page" do
              get :show, params: { id: invitation.key }
              expect(response).to render_template("assignment_invitations/join_roster")
            end
          end
        end

        context "with ignore param" do
          it "will bring you to the show page" do
            get :show, params: { id: invitation.key, roster: "ignore" }
            expect(response).to have_http_status(:success)
            expect(response).to render_template("assignment_invitations/show")
          end
        end
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

    it "sends an event to statsd" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_invitation.accept")

      allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for).with(user).and_return(result)

      patch :accept, params: { id: invitation.key }
    end

    context "with repo setup enabled", :vcr do
      before do
        GitHubClassroom.flipper[:repo_setup].enable
      end

      it "redirects to success after accepting assignment without starter code" do
        allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for).with(user).and_return(result)

        patch :accept, params: { id: invitation.key }
        expect(response).to redirect_to(success_assignment_invitation_url(invitation))
      end

      it "redirects to setup after accepting assignment with starter code" do
        assignment = create(:assignment, title: "Learn Clojure", starter_code_repo_id: 1_062_897,
                                         organization: organization)
        invitation2 = create(:assignment_invitation, assignment: assignment)
        assignment_repo = create(:assignment_repo, assignment: invitation2.assignment, user: user)

        result2 = AssignmentRepo::Creator::Result.success(assignment_repo)

        allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for).with(user).and_return(result2)

        patch :accept, params: { id: invitation2.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation2))
      end
    end
  end

  describe "GET #setup", :vcr do
    let(:assignment) do
      create(:assignment, title: "Learn Clojure", starter_code_repo_id: 1_062_897, organization: organization)
    end

    let(:invitation) { create(:assignment_invitation, assignment: assignment) }

    before do
      GitHubClassroom.flipper[:repo_setup].enable
    end

    context "unauthenticated request" do
      it "redirects the new user to sign in with GitHub" do
        get :setup, params: { id: invitation.key }
        expect(response).to redirect_to(login_path)
      end
    end

    context "authenticated request" do
      before(:each) do
        sign_in_as(user)

        assignment_repo = create(:assignment_repo, assignment: invitation.assignment, github_repo_id: 8485, user: user)
        allow(assignment_repo).to receive(:github_repository).and_return(unconfigured_repo)

        result = AssignmentRepo::Creator::Result.success(assignment_repo)
        allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for).with(user).and_return(result)
      end

      it "shows setup" do
        get :setup, params: { id: invitation.key }

        expect(request.url).to eq(setup_assignment_invitation_url(invitation))
        expect(response).to have_http_status(:success)
        expect(response).to render_template("assignment_invitations/setup")
      end
    end
  end

  describe "PATCH #setup_progress", :vcr do
    let(:assignment) do
      create(:assignment, title: "Learn Clojure", starter_code_repo_id: 1_062_897, organization: organization)
    end

    let(:invitation) { create(:assignment_invitation, assignment: assignment) }

    before(:each) do
      GitHubClassroom.flipper[:repo_setup].enable
      sign_in_as(user)

      @assignment_repo = create(:assignment_repo, assignment: invitation.assignment, github_repo_id: 8485, user: user)

      result = AssignmentRepo::Creator::Result.success(@assignment_repo)
      allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for).with(user).and_return(result)
    end

    it "gives status of complete when configured" do
      @assignment_repo.configured!
      allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(configured_repo)
      patch :setup_progress, params: { id: invitation.key }

      expect(response).to have_http_status(:success)
      expect(response.header["Content-Type"]).to include "application/json"
      progress = JSON(response.body)
      expect(progress["status"]).to eq("complete")
    end

    it "gives status of configuring when unconfigured" do
      @assignment_repo.configuring!
      allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(unconfigured_repo)
      patch :setup_progress, params: { id: invitation.key }

      expect(response).to have_http_status(:success)
      expect(response.header["Content-Type"]).to include "application/json"
      progress = JSON(response.body)
      expect(progress["status"]).to eq("configuring")
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

  describe "PATCH #join_roster", :vcr do
    before do
      organization.roster = create(:roster)
      organization.save
    end

    context "unauthenticated request" do
      it "redirects the new user to sign in with GitHub" do
        patch :join_roster, params: { id: invitation.key }
        expect(response).to redirect_to(login_path)
      end
    end

    context "authenticated request" do
      before(:each) do
        sign_in_as(user)
      end

      context "with invalid roster entry id" do
        before do
          patch :join_roster, params: { id: invitation.key, roster_entry_id: "not_an_id" }
        end

        it "renders join_roster view" do
          expect(response).to render_template("assignment_invitations/join_roster")
        end

        it "shows flash message" do
          expect(flash[:error]).to be_present
        end
      end

      context "with a valid roster entry id" do
        before do
          entry = organization.roster.roster_entries.first
          patch :join_roster, params: { id: invitation.key, roster_entry_id: entry.id }
        end

        it "adds the user to the roster entry" do
          expect(RosterEntry.find_by(user: user, roster: organization.roster)).to be_present
        end

        it "renders show" do
          expect(response).to redirect_to(assignment_invitation_url(invitation))
        end
      end
    end
  end
end
