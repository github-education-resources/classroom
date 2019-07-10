# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentInvitationsController, type: :controller do
  let(:organization)  { classroom_org     }
  let(:user)          { classroom_student }
  let(:config_branch) { ClassroomConfig::CONFIG_BRANCH }

  let(:invitation)      { create(:assignment_invitation, organization: organization) }
  let(:invite_status)   { create(:invite_status, user: user, assignment_invitation: invitation) }
  let(:assignment_repo) { create(:assignment_repo, user: user, assignment: invitation.assignment) }

  let(:unconfigured_repo) { stub_repository("template") }
  let(:configured_repo)   { stub_repository("configured-repo") }

  describe "route_based_on_status", :vcr do
    before do
      sign_in_as(user)
    end

    describe "unaccepted!" do
      it "gets #show" do
        invite_status.unaccepted!
        get :show, params: { id: invitation.key }
        expect(response).to render_template(:show)
      end

      it "gets #setup and redirects to #show" do
        invite_status.unaccepted!
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(assignment_invitation_url(invitation))
      end

      it "gets #success and redirects to #show" do
        invite_status.unaccepted!
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(assignment_invitation_url(invitation))
      end
    end

    describe "accepted!" do
      it "gets #setup" do
        invite_status.accepted!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #show and redirects to #setup" do
        invite_status.accepted!
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end

      it "gets #success and redirects to #setup" do
        invite_status.accepted!
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end
    end

    describe "waiting!" do
      it "gets #setup" do
        invite_status.waiting!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #show and redirects to #setup" do
        invite_status.waiting!
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end

      it "gets #success and redirects to #setup" do
        invite_status.waiting!
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end
    end

    describe "creating_repo!" do
      it "gets #setup" do
        invite_status.creating_repo!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #show and redirects to #setup" do
        invite_status.creating_repo!
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end

      it "gets #success and redirects to #setup" do
        invite_status.creating_repo!
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end
    end

    describe "errored_creating_repo!" do
      it "gets #setup" do
        invite_status.errored_creating_repo!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #show and redirects to #setup" do
        invite_status.errored_creating_repo!
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end

      it "gets #success and redirects to #setup" do
        invite_status.errored_creating_repo!
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end
    end

    describe "importing_starter_code!" do
      it "gets #setup" do
        invite_status.importing_starter_code!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #show and redirects to #setup" do
        invite_status.importing_starter_code!
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end

      it "gets #success and redirects to #setup" do
        invite_status.importing_starter_code!
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end
    end

    describe "errored_importing_starter_code!" do
      it "gets #setup" do
        invite_status.errored_importing_starter_code!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #show and redirects to #setup" do
        invite_status.errored_importing_starter_code!
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end

      it "gets #success and redirects to #setup" do
        invite_status.errored_importing_starter_code!
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end
    end

    describe "completed!" do
      it "gets #show and redirects to #success" do
        invite_status.completed!
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(success_assignment_invitation_url(invitation))
      end

      it "gets #setup and redirects to #success" do
        invite_status.completed!
        get :setup, params: { id: invitation.key }
        expect(response).to redirect_to(success_assignment_invitation_url(invitation))
      end
    end
  end

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

        context "previous acceptee" do
          it "redirects to success" do
            assignment_repo = create(:assignment_repo, assignment: invitation.assignment, user: user)
            AssignmentRepo::Creator::Result.success(assignment_repo)
            invitation.status(user).accepted!

            get :show, params: { id: invitation.key }

            expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
          end
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
      expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_invitation.accept")

      allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for).with(user).and_return(result)

      patch :accept, params: { id: invitation.key }
    end

    context "redeem returns an fail" do
      let(:result) { AssignmentRepo::Creator::Result.failed("Couldn't accept the invitation") }

      before do
        allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for).with(user).and_return(result)
      end

      it "records error stat" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_invitation.fail")
        patch :accept, params: { id: invitation.key }
      end

      it "flash error" do
        patch :accept, params: { id: invitation.key }
        expect(flash[:error]).to be_present
      end

      it "redirects to #show" do
        patch :accept, params: { id: invitation.key }
        expect(response.redirect_url).to eq(assignment_invitation_url(invitation))
      end
    end

    context "with import resiliency enabled" do
      it "sends an event to statsd" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_invitation.accept")

        allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for)
          .with(user)
          .and_return(result)

        patch :accept, params: { id: invitation.key }
      end

      it "redirects to success when AssignmentRepo already exists" do
        allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for)
          .with(user)
          .and_return(result)

        patch :accept, params: { id: invitation.key }
        expect(response).to redirect_to(success_assignment_invitation_url(invitation))
      end

      it "redirects to setup when AssignmentRepo already exists but isn't completed" do
        invite_status.waiting!
        allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for)
          .with(user)
          .and_return(result)

        patch :accept, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end

      it "redirects to setup when AssignmentRepo doesn't already exist" do
        invite_status.accepted!
        allow_any_instance_of(AssignmentInvitation).to receive(:redeem_for)
          .with(user)
          .and_return(AssignmentRepo::Creator::Result.pending)

        patch :accept, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end
    end
  end

  describe "POST #create_repo", :vcr do
    before do
      sign_in_as(user)
    end

    context "with import resiliency enabled" do
      context "when invitation status is accepted" do
        before do
          invite_status.accepted!
        end

        it "enqueues a CreateRepositoryJob" do
          assert_enqueued_jobs 1, only: AssignmentRepo::CreateGitHubRepositoryJob do
            post :create_repo, params: { id: invitation.key }
          end
        end

        it "says a job was succesfully kicked off" do
          post :create_repo, params: { id: invitation.key }
          expect(json)
            .to eq(
              "job_started" => true,
              "status" => "waiting",
              "repo_url" => nil
            )
        end
      end

      context "when invitation status is errored" do
        before do
          invite_status.errored_creating_repo!
        end

        it "deletes an assignment repo if one already exists and is empty" do
          Octokit.reset!
          client = oauth_client

          empty_github_repository = GitHubRepository.new(client, 141_328_892)
          AssignmentRepo.create(assignment: invitation.assignment, github_repo_id: 8485, user: user)
          allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(empty_github_repository)
          expect_any_instance_of(AssignmentRepo).to receive(:destroy)
          post :create_repo, params: { id: invitation.key }
        end

        it "doesn't delete an assignment repo when one already exists and is not empty" do
          Octokit.reset!
          client = oauth_client

          github_repository = GitHubRepository.new(client, 35_079_964)
          AssignmentRepo.create(assignment: invitation.assignment, github_repo_id: 8485, user: user)
          allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(github_repository)
          expect_any_instance_of(AssignmentRepo).not_to receive(:destroy)
          post :create_repo, params: { id: invitation.key }
        end

        it "enqueues a CreateRepositoryJob" do
          assert_enqueued_jobs 1, only: AssignmentRepo::CreateGitHubRepositoryJob do
            post :create_repo, params: { id: invitation.key }
          end
        end

        it "says a job was succesfully kicked off" do
          post :create_repo, params: { id: invitation.key }
          expect(json)
            .to eq(
              "job_started" => true,
              "status" => "waiting",
              "repo_url" => nil
            )
        end

        it "reports an error was retried" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.retry")
          post :create_repo, params: { id: invitation.key }
        end

        it "reports an error importing was retried" do
          invite_status.errored_importing_starter_code!
          expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.import.retry")
          post :create_repo, params: { id: invitation.key }
        end
      end

      context "when a repo exists" do
        before do
          invite_status.importing_starter_code!
          octokit_repo_id = 417_862
          assignment_repo = AssignmentRepo.new(github_repo_id: octokit_repo_id, assignment: invitation.assignment)
          expect_any_instance_of(AssignmentInvitationsController)
            .to receive(:current_submission)
            .and_return(assignment_repo)
        end

        it "has a repo_url" do
          post :create_repo, params: { id: invitation.key }
          expect(json)
            .to eq(
              "job_started" => false,
              "status" => "importing_starter_code",
              "repo_url" => "https://github.com/octokit/octokit.rb"
            )
        end
      end

      context "when invitation status is anything else" do
        before do
          invite_status.unaccepted!
        end

        it "does not enqueue a CreateRepositoryJob" do
          assert_enqueued_jobs 0, only: AssignmentRepo::CreateGitHubRepositoryJob do
            post :create_repo, params: { id: invitation.key }
          end
        end

        it "says a job was unsuccesfully kicked off" do
          post :create_repo, params: { id: invitation.key }
          expect(json)
            .to eq(
              "job_started" => false,
              "status" => "unaccepted",
              "repo_url" => nil
            )
        end
      end
    end
  end

  describe "GET #setup", :vcr do
    before(:each) do
      sign_in_as(user)
    end
  end

  describe "GET #progress", :vcr do
    before do
      sign_in_as(user)
    end

    context "with import resiliency enabled" do
      it "returns the invite_status" do
        invite_status.errored_creating_repo!
        get :progress, params: { id: invitation.key }
        expect(json).to eq(
          "status" => "errored_creating_repo",
          "repo_url" => nil
        )
      end

      context "when the github_repository already exists" do
        it "has a repo_url field present" do
          octokit_repo_id = 417_862
          assignment_repo = AssignmentRepo.new(github_repo_id: octokit_repo_id, assignment: invitation.assignment)
          expect_any_instance_of(AssignmentInvitationsController)
            .to receive(:current_submission)
            .and_return(assignment_repo)
          get :progress, params: { id: invitation.key }
          expect(json)
            .to eq(
              "status" => "unaccepted",
              "repo_url" => "https://github.com/octokit/octokit.rb"
            )
        end
      end
    end
  end

  describe "GET #success", :vcr do
    let(:assignment) do
      create(:assignment, title: "Learn Clojure", starter_code_repo_id: 1_062_897, organization: organization)
    end

    let(:invitation) { create(:assignment_invitation, assignment: assignment) }
    let(:invite_status) { create(:invite_status, assignment_invitation: invitation, user: user) }

    before(:each) do
      sign_in_as(user)
      result = AssignmentRepo::Creator.perform(assignment: assignment, user: user)
      @assignment_repo = result.assignment_repo
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    describe "import resiliency enabled" do
      it "redirects to setup when no GitHub repo present" do
        invite_status.completed!
        expect_any_instance_of(GitHubRepository)
          .to receive(:present?)
          .with(headers: GitHub::APIHeaders.no_cache_no_store)
          .and_return(false)
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
      end

      it "sets invite status to accepted when no GitHub repo present" do
        invite_status.completed!
        expect_any_instance_of(GitHubRepository)
          .to receive(:present?)
          .with(headers: GitHub::APIHeaders.no_cache_no_store)
          .and_return(false)
        get :success, params: { id: invitation.key }
        expect(invite_status.reload.accepted?).to be_truthy
      end

      it "renders #success" do
        invite_status.completed!
        expect_any_instance_of(GitHubRepository)
          .to receive(:present?)
          .with(headers: GitHub::APIHeaders.no_cache_no_store)
          .and_return(true)
        get :success, params: { id: invitation.key }
        expect(response).to render_template(:success)
      end

      it "doesn't 404 when there is no current_submission" do
        invite_status.completed!
        expect_any_instance_of(AssignmentInvitationsController)
          .to receive(:current_submission)
          .twice
          .and_return(nil)
        get :success, params: { id: invitation.key }
        expect(response.status).to_not eq(404)
      end

      it "redirects to setup when there is no current_submission" do
        invite_status.completed!
        expect_any_instance_of(AssignmentInvitationsController)
          .to receive(:current_submission)
          .twice
          .and_return(nil)
        get :success, params: { id: invitation.key }
        expect(response).to redirect_to(setup_assignment_invitation_url(invitation))
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
