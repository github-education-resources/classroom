# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentInvitationsController, type: :controller do
  let(:organization) { classroom_org }
  let(:student)      { classroom_student }
  let(:group_assignment) do
    options = {
      title: "HTML5",
      slug: "html5",
      organization: organization
    }
    create(:group_assignment, options)
  end
  let(:grouping) { group_assignment.grouping }
  let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name).id }
  let(:group) do
    group = create(:group, grouping: grouping, github_team_id: github_team_id)
    group.repo_accesses << RepoAccess.create(user: student, organization: organization)
    group
  end
  let(:invitation)    { create(:group_assignment_invitation, group_assignment: group_assignment) }
  let(:invite_status) { invitation.status(group) }

  describe "route_based_on_status", :vcr do
    before(:each) do
      sign_in_as(student)
    end

    after(:each) do
      GroupInviteStatus.destroy_all
    end

    describe "unaccepted!" do
      it "gets #setup and redirects to #show" do
        invite_status.unaccepted!
        get :setup, params: { id: invitation.key }
        expect(response).to redirect_to(group_assignment_invitation_url(invitation))
      end

      it "gets #successful_invitation and redirects to #show" do
        invite_status.unaccepted!
        get :successful_invitation, params: { id: invitation.key }
        expect(response).to redirect_to(group_assignment_invitation_url(invitation))
      end
    end

    describe "accepted!" do
      it "gets #setup" do
        invite_status.accepted!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #successful_invitation and redirects to #setup" do
        invite_status.accepted!
        get :successful_invitation, params: { id: invitation.key }
        expect(response).to redirect_to(setup_group_assignment_invitation_url(invitation))
      end
    end

    describe "waiting!" do
      it "gets #setup" do
        invite_status.waiting!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #successful_invitation and redirects to #setup" do
        invite_status.waiting!
        get :successful_invitation, params: { id: invitation.key }
        expect(response).to redirect_to(setup_group_assignment_invitation_url(invitation))
      end
    end

    describe "creating_repo!" do
      it "gets #setup" do
        invite_status.creating_repo!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #successful_invitation and redirects to #setup" do
        invite_status.creating_repo!
        get :successful_invitation, params: { id: invitation.key }
        expect(response).to redirect_to(setup_group_assignment_invitation_url(invitation))
      end
    end

    describe "errored_creating_repo!" do
      it "gets #setup" do
        invite_status.errored_creating_repo!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #successful_invitation and redirects to #setup" do
        invite_status.errored_creating_repo!
        get :successful_invitation, params: { id: invitation.key }
        expect(response).to redirect_to(setup_group_assignment_invitation_url(invitation))
      end
    end

    describe "importing_starter_code!" do
      it "gets #setup" do
        invite_status.importing_starter_code!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #successful_invitation and redirects to #setup" do
        invite_status.importing_starter_code!
        get :successful_invitation, params: { id: invitation.key }
        expect(response).to redirect_to(setup_group_assignment_invitation_url(invitation))
      end
    end

    describe "errored_importing_starter_code!" do
      it "gets #setup" do
        invite_status.errored_importing_starter_code!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end

      it "gets #successful_invitation and redirects to #setup" do
        invite_status.errored_importing_starter_code!
        get :successful_invitation, params: { id: invitation.key }
        expect(response).to redirect_to(setup_group_assignment_invitation_url(invitation))
      end
    end

    describe "completed!" do
      it "gets #setup and redirects to #successful_invitation" do
        invite_status.completed!
        get :setup, params: { id: invitation.key }
        expect(response).to redirect_to(successful_invitation_group_assignment_invitation_path(invitation))
      end

      # see GET #successful_invitation tests
    end
  end

  describe "GET #show", :vcr do
    context "unauthenticated request" do
      it "redirects the new student to sign in with GitHub" do
        get :show, params: { id: invitation.key }
        expect(response).to redirect_to(login_path)
      end
    end

    context "authenticated request" do
      before(:each) do
        sign_in_as(student)
      end

      context "no roster" do
        it "will bring you to the page" do
          get :show, params: { id: invitation.key }
          expect(response).to have_http_status(:success)
          expect(response).to render_template("group_assignment_invitations/show")
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
              RosterEntry.create(roster: organization.roster, user: student, identifier: "a@b.c")
            end

            it "will bring you to the show page" do
              get :show, params: { id: invitation.key }
              expect(response).to render_template("group_assignment_invitations/show")
            end
          end

          context "when user is not on the roster" do
            it "will bring you to the join_roster page" do
              get :show, params: { id: invitation.key }
              expect(response).to render_template("group_assignment_invitations/join_roster")
            end
          end
        end

        context "with ignore param" do
          it "will bring you to the show page" do
            get :show, params: { id: invitation.key, roster: "ignore" }
            expect(response).to have_http_status(:success)
            expect(response).to render_template("group_assignment_invitations/show")
          end
        end
      end
    end
  end

  describe "GET #accept", :vcr do
    context "user is already a member of a group in the grouping" do
      before do
        sign_in_as(student)
        group
      end

      after do
        GroupAssignmentRepo.destroy_all
      end

      it "returns success status" do
        get :accept, params: { id: invitation.key }
        expect(response).to have_http_status(:success)
      end

      it "render :accept" do
        get :accept, params: { id: invitation.key }
        expect(response).to render_template(:accept)
      end

      context "with group import resiliency enabled" do
        it "renders accept" do
          invite_status.unaccepted!
          get :accept, params: { id: invitation.key }
          expect(response).to render_template(:accept)
        end
      end
    end

    context "user has no group" do
      before do
        sign_in_as(student)
      end
      it "redirects to #show if user manually visits #accept" do
        get :accept, params: { id: invitation.key }
        expect(response).to redirect_to(group_assignment_invitation_path(invitation))
      end
    end
  end

  describe "PATCH #accept_invitation", :vcr do
    context "authenticated request" do
      before(:each) do
        request.env["HTTP_REFERER"] = "http://classroomtest.com/group-assignment-invitations/#{invitation.key}"
        sign_in_as(student)
      end

      after(:each) do
        GroupAssignmentRepo.destroy_all
      end

      it "sends an event to statsd" do
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
          .with("group_exercise_invitation.accept")
        patch :accept_invitation, params: { id: invitation.key, group: { title: "Code Squad" } }
      end

      context "invitations are disabled" do
        before do
          group_assignment.update(invitations_enabled: false)
          patch :accept_invitation, params: { id: invitation.key, group: { title: "Code Squad" } }
        end

        it "redirects" do
          expect(response).to redirect_to(group_assignment_invitation_path)
        end

        it "has errors" do
          expect(flash[:error]).to eq("Invitations for this assignment have been disabled.")
        end

        it "doesn't record a failure" do
          expect(GitHubClassroom.statsd).to_not receive(:increment)
        end
      end

      it "does not allow users to join a group that is not apart of the grouping" do
        other_grouping = create(:grouping, organization: organization)
        other_group    = create(:group, grouping: other_grouping, github_team_id: 2_976_595)

        patch :accept_invitation, params: { id: invitation.key, group: { id: other_group.id } }

        expect(group_assignment.group_assignment_repos.count).to eql(0)
        expect(student.repo_accesses.count).to eql(0)
      end

      context "group has reached maximum number of members", :vcr do
        before(:each) do
          allow_any_instance_of(RepoAccess).to receive(:silently_remove_organization_member).and_return(true)
          group_assignment.update(max_members: 1)
        end

        it "does not allow user to join" do
          expect_any_instance_of(ApplicationController).to receive(:flash_and_redirect_back_with_message)
          patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }

          expect(invitation.status(group).status).to eq("unaccepted")
        end
      end

      context "group has not reached maximum number of members" do
        let(:group) { create(:group, grouping: grouping, github_team_id: 2_973_107) }

        before(:each) do
          group_assignment.update(max_members: 1)
        end

        it "allows user to join" do
          patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
        end
      end

      context "group does not have maximum number of members" do
        let(:group) { create(:group, grouping: grouping, github_team_id: 2_973_107) }

        it "allows user to join" do
          patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
          expect(student.repo_accesses.count).to eql(1)
        end
      end

      context "assignment has reached maximum number of teams" do
        let(:existing_group) { create(:group, grouping: grouping, github_team_id: 2_973_107) }
        let(:new_group) { create(:group, grouping: grouping, github_team_id: 2_973_108) }
        let(:second_invitation) { create(:group_assignment_invitation, group_assignment: group_assignment) }

        before(:each) do
          group_assignment.update(max_teams: 1)
          patch :accept_invitation, params: { id: invitation.key, group: { title: existing_group.title } }
        end

        it "does not allow a user to create a team" do
          expect_any_instance_of(ApplicationController).to receive(:flash_and_redirect_back_with_message)
          patch :accept_invitation, params: { id: second_invitation.key, group: { title: new_group.title } }
        end
      end

      context "assignment has not reached maximum number of teams" do
        let(:existing_group) { create(:group, grouping: grouping, github_team_id: 2_973_107) }
        let(:new_group) { create(:group, grouping: grouping, github_team_id: 2_973_108) }
        let(:second_invitation) { create(:group_assignment_invitation, group_assignment: group_assignment) }

        before(:each) do
          group_assignment.update(max_teams: 2)
          patch :accept_invitation, params: { id: invitation.key, group: { title: existing_group.title } }
        end

        it "allows user to create a team" do
          patch :accept_invitation, params: { id: second_invitation.key, group: { title: new_group.title } }
          expect(group_assignment.grouping.groups.count).to eql(2)
        end
      end

      context "assignment does not have maximum number of teams" do
        let(:existing_group) { create(:group, grouping: grouping, github_team_id: 2_973_107) }
        let(:new_group) { create(:group, grouping: grouping, github_team_id: 2_973_108) }
        let(:second_invitation) { create(:group_assignment_invitation, group_assignment: group_assignment) }

        before(:each) do
          patch :accept_invitation, params: { id: invitation.key, group: { title: existing_group.title } }
        end

        it "allows user to create a team" do
          patch :accept_invitation, params: { id: second_invitation.key, group: { title: new_group.title } }
          expect(group_assignment.grouping.groups.count).to eql(2)
        end
      end

      context "with group import resiliency enabled" do
        describe "success" do
          it "sends an event to statsd" do
            expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_invitation.accept")
            patch :accept_invitation, params: { id: invitation.key, group: { title: group.title } }
          end

          it "creates a team" do
            patch :accept_invitation, params: { id: invitation.key, group: { title: group.title } }
            expect(student.repo_accesses.count).to eql(1)
          end

          it "does not create a repo" do
            patch :accept_invitation, params: { id: invitation.key, group: { title: group.title } }
            expect(group_assignment.group_assignment_repos.count).to eql(0)
          end

          it "redirects to #setup" do
            patch :accept_invitation, params: { id: invitation.key, group: { title: group.title } }
            expect(response).to redirect_to(setup_group_assignment_invitation_path)
          end

          it "makes the invite status accepted" do
            patch :accept_invitation, params: { id: invitation.key, group: { title: group.title } }
            expect(invitation.status(Group.all.first).accepted?).to be_truthy
          end

          context "joins an existing group" do
            let(:group) { create(:group, grouping: grouping, github_team_id: 2_973_107) }

            it "creates a repo_access" do
              patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
              expect(student.repo_accesses.count).to eql(1)
            end

            context "groups status is already completed" do
              before do
                invitation.status(group).completed!
              end

              it "redirects to #successful_invitation" do
                patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
                expect(response).to redirect_to(successful_invitation_group_assignment_invitation_path)
              end
            end
          end
        end

        describe "failed" do
          it "fails if assignment invitations are disabled" do
            group_assignment.update(invitations_enabled: false)

            patch :accept_invitation, params: { id: invitation.key, group: { title: group.title } }
            expect(response).to redirect_to(group_assignment_invitation_path)
          end
        end
      end
    end
  end

  describe "GET #setup", :vcr do
    before(:each) do
      sign_in_as(student)
    end

    context "with group import resiliency enabled" do
      it "renders setup" do
        invite_status.creating_repo!
        get :setup, params: { id: invitation.key }
        expect(response).to render_template(:setup)
      end
    end
  end

  describe "POST #create_repo", :vcr do
    before(:each) do
      sign_in_as(student)
    end

    context "with group import resiliency enabled" do
      invalid_statuses = GroupInviteStatus::SETUP_STATUSES - ["accepted"]
      valid_statuses = GroupInviteStatus::ERRORED_STATUSES + ["accepted"]

      context "invalid statuses" do
        invalid_statuses.each do |status|
          context "when #{status}" do
            before do
              invite_status.update(status: status)
            end

            it "didn't kick off a job" do
              expect { post :create_repo, params: { id: invitation.key } }
                .to_not have_enqueued_job(GroupAssignmentRepo::CreateGitHubRepositoryJob)
            end
          end
        end

        invalid_statuses.each do |status|
          context "when #{status}" do
            before do
              invite_status.update(status: status)
              post :create_repo, params: { id: invitation.key }
            end

            it "has a successful response" do
              expect(response.status).to eq(200)
            end

            it "has a job_started of false" do
              expect(json["job_started"]).to eq(false)
            end

            it "has a status of #{status}" do
              expect(json["status"]).to eq(status)
            end
          end
        end
      end

      context "valid statuses" do
        valid_statuses.each do |status|
          context "when #{status}" do
            before do
              invite_status.update(status: status)
            end

            it "kick off a job" do
              expect { post :create_repo, params: { id: invitation.key } }
                .to have_enqueued_job(GroupAssignmentRepo::CreateGitHubRepositoryJob)
            end
          end
        end

        valid_statuses.each do |status|
          context "when #{status}" do
            before do
              invite_status.update(status: status)
              post :create_repo, params: { id: invitation.key }
            end

            it "has a successful response" do
              expect(response.status).to eq(200)
            end

            it "has a job_started of true" do
              expect(json["job_started"]).to eq(true)
            end

            it "has a status of waiting" do
              expect(json["status"]).to eq("waiting")
            end
          end
        end
      end
    end
  end

  describe "GET #progress", :vcr do
    before(:each) do
      sign_in_as(student)
    end

    context "with group import resiliency enabled" do
      context "GroupAssignemntRepo not present" do
        before do
          get :progress, params: { id: invitation.key }
        end

        it "returns status" do
          expect(json["status"]).to be_nil
        end

        it "doesn't have a repo_url" do
          expect(json["repo_url"]).to eq(nil)
        end
      end

      context "GroupAssignmentRepo already present" do
        before do
          GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
          get :progress, params: { id: invitation.key }
        end

        it "has a repo_url" do
          expect(json["repo_url"].present?).to be_truthy
        end
      end
    end
  end

  describe "GET #successful_invitation", :vcr do
    let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name).id }
    let(:group) do
      group = create(:group, grouping: grouping, github_team_id: github_team_id)
      group.repo_accesses << RepoAccess.create(user: student, organization: organization)
      group
    end

    before(:each) do
      sign_in_as(student)
      result = GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
      @group_assignment_repo = result.group_assignment_repo
    end

    after(:each) do
      GroupAssignmentRepo.destroy_all
    end

    context "with group import resiliency enabled" do
      it "renders #successful_invitation" do
        invite_status.completed!
        get :successful_invitation, params: { id: invitation.key }
        expect(response).to render_template(:successful_invitation)
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
        sign_in_as(student)
      end

      context "with invalid roster entry id" do
        before do
          patch :join_roster, params: { id: invitation.key, roster_entry_id: "not_an_id" }
        end

        it "renders join_roster view" do
          expect(response).to render_template("group_assignment_invitations/join_roster")
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
          expect(RosterEntry.find_by(user: student, roster: organization.roster)).to be_present
        end

        it "renders show" do
          expect(response).to redirect_to(group_assignment_invitation_url(invitation))
        end
      end
    end
  end
end
