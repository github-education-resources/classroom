# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentInvitationsController, type: :controller do
  let(:organization) { classroom_org     }
  let(:student)      { classroom_student }

  let(:group_assignment) do
    options = {
      title: "HTML5",
      slug: "html5",
      organization: organization
    }

    create(:group_assignment, options)
  end

  let(:grouping)   { group_assignment.grouping                                                }
  let(:invitation) { create(:group_assignment_invitation, group_assignment: group_assignment) }

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
    let(:group) { Group.create(title: "The Group", grouping: group_assignment.grouping) }

    context "user is already a member of a group in the grouping" do
      render_views

      before do
        sign_in_as(student)
        group.repo_accesses << RepoAccess.create(user: student, organization: organization)
      end

      after do
        RepoAccess.destroy_all
        Group.destroy_all
        GroupAssignmentRepo.destroy_all
      end

      it "returns success status" do
        get :accept, params: { id: invitation.key }
        expect(response).to have_http_status(:success)
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
        RepoAccess.destroy_all
        Group.destroy_all
        GroupAssignmentRepo.destroy_all
      end

      it "redeems the users invitation" do
        patch :accept_invitation, params: { id: invitation.key, group: { title: "Code Squad" } }

        expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/teams"))
        expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))

        expect(group_assignment.group_assignment_repos.count).to eql(1)
        expect(student.repo_accesses.count).to eql(1)
      end

      it "sends an event to statsd" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_invitation.accept")

        patch :accept_invitation, params: { id: invitation.key, group: { title: "Code Squad" } }
      end

      it "fails if assignment invitations are disabled" do
        group_assignment.update(invitations_enabled: false)

        patch :accept_invitation, params: { id: invitation.key, group: { title: "Code Squad" } }
        expect(response).to redirect_to(group_assignment_invitation_path)
      end

      it "does not allow users to join a group that is not apart of the grouping" do
        other_grouping = create(:grouping, organization: organization)
        other_group    = Group.create(title: "The Group", grouping: other_grouping)

        patch :accept_invitation, params: { id: invitation.key, group: { id: other_group.id } }

        expect(group_assignment.group_assignment_repos.count).to eql(0)
        expect(student.repo_accesses.count).to eql(0)
      end

      context "group has reached maximum number of members", :vcr do
        let(:group) { Group.create(title: "The Group", grouping: grouping) }

        before(:each) do
          allow_any_instance_of(RepoAccess).to receive(:silently_remove_organization_member).and_return(true)
          group_assignment.update(max_members: 1)
          group.repo_accesses << RepoAccess.create(user: student, organization: organization)
        end

        it "does not allow user to join" do
          expect_any_instance_of(ApplicationController).to receive(:flash_and_redirect_back_with_message)
          patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
        end

        it "sends an event to statsd" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("exception.swallowed",
                                                                     tags: [ApplicationController::NotAuthorized.to_s])
          expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_invitation.fail")

          patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
        end
      end

      context "group has not reached maximum number of members" do
        let(:group) { Group.create(title: "The Group", grouping: grouping) }

        before(:each) do
          group_assignment.update(max_members: 1)
        end

        it "allows user to join" do
          patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
        end
      end

      context "group does not have maximum number of members" do
        let(:group) { Group.create(title: "The Group", grouping: grouping) }

        it "allows user to join" do
          patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
          expect(group_assignment.group_assignment_repos.count).to eql(1)
          expect(student.repo_accesses.count).to eql(1)
        end
      end

      context "github repository with the same name already exists" do
        before do
          group = Group.create(title: "The Group", grouping: grouping)
          group_assignment_repo = GroupAssignmentRepo.create!(group_assignment: group_assignment, group: group)
          @original_repository = organization.github_client.repository(group_assignment_repo.github_repo_id)
          group_assignment_repo.delete
          patch :accept_invitation, params: { id: invitation.key, group: { id: group.id } }
        end

        it "creates a new group assignment repo" do
          expect(group_assignment.group_assignment_repos.count).to eql(1)
        end

        it "new repository name has expected suffix" do
          expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
            .with(body: /^.*#{@original_repository.name}-1.*$/)
        end

        after do
          organization.github_client.delete_repository(@original_repository.id)
          GroupAssignmentRepo.destroy_all
          Group.destroy_all
        end
      end
    end
  end

  describe "GET #setup", :vcr do
    let(:repo_access) { RepoAccess.create(user: student, organization: organization) }
    let(:group)       { Group.create(title: "Group 1", grouping: grouping) }

    context "repo setup enabled" do
      before { GitHubClassroom.flipper[:repo_setup].enable }

      context "unauthenticated request" do
        it "redirects the new user to sign in with GitHub" do
          get :setup, params: { id: invitation.key }
          expect(response).to redirect_to(login_path)
        end
      end

      context "authenticated request" do
        before(:each) do
          allow_any_instance_of(GroupAssignment).to receive(:starter_code_repo_id).and_return(1_062_897)

          group.repo_accesses << repo_access
          @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
          sign_in_as(student)
        end

        after(:each) do
          group.destroy
          repo_access.destroy
          @group_assignment_repo.destroy if @group_assignment_repo.present?
        end

        it "shows setup" do
          get :setup, params: { id: invitation.key }
          expect(request.url).to eq(setup_group_assignment_invitation_url(invitation))
          expect(response).to have_http_status(:success)
          expect(response).to render_template("group_assignment_invitations/setup")
        end
      end
    end

    context "repo setup disabled" do
      before { GitHubClassroom.flipper[:repo_setup].disable }

      context "unauthenticated request" do
        it "redirects the new user to sign in with GitHub" do
          get :setup, params: { id: invitation.key }
          expect(response).to redirect_to(login_path)
        end
      end

      context "authenticated request" do
        before(:each) do
          allow_any_instance_of(GroupAssignment).to receive(:starter_code_repo_id).and_return(1_062_897)

          group.repo_accesses << repo_access
          @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
          sign_in_as(student)
        end

        after(:each) do
          group.destroy
          repo_access.destroy
          @group_assignment_repo.destroy if @group_assignment_repo.present?
        end

        it "redirects to the success page" do
          get :setup, params: { id: invitation.key }
          expect(request.url).to eq(setup_group_assignment_invitation_url(invitation))
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(successful_invitation_group_assignment_invitation_url)
        end
      end
    end
  end

  describe "PATCH #setup_progress", :vcr do
    let(:unconfigured_repo) { stub_repository("template") }
    let(:configured_repo) { stub_repository("configured-repo") }

    let(:repo_access) { RepoAccess.create(user: student, organization: organization) }
    let(:group)       { Group.create(title: "Group 1", grouping: grouping) }

    before do
      GitHubClassroom.flipper[:repo_setup].enable
    end

    before(:each) do
      allow_any_instance_of(GroupAssignment).to receive(:starter_code_repo_id).and_return(1_062_897)

      group.repo_accesses << repo_access
      @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
      sign_in_as(student)
    end

    after(:each) do
      group.destroy
      repo_access.destroy
      @group_assignment_repo.destroy if @group_assignment_repo.present?
    end

    it "gives status of complete when configured" do
      @group_assignment_repo.configured!
      allow_any_instance_of(GroupAssignmentRepo).to receive(:github_repository).and_return(configured_repo)
      patch :setup_progress, params: { id: invitation.key }

      expect(response).to have_http_status(:success)
      expect(response.header["Content-Type"]).to include "application/json"
      progress = JSON(response.body)
      expect(progress["status"]).to eq("complete")
    end

    it "gives status of configuring when unconfigured" do
      @group_assignment_repo.configuring!
      allow_any_instance_of(GroupAssignmentRepo).to receive(:github_repository).and_return(unconfigured_repo)
      patch :setup_progress, params: { id: invitation.key }

      expect(response).to have_http_status(:success)
      expect(response.header["Content-Type"]).to include "application/json"
      progress = JSON(response.body)
      expect(progress["status"]).to eq("configuring")
    end
  end

  describe "GET #successful_invitation" do
    let(:group) { Group.create(title: "The Group", grouping: grouping) }

    before(:each) do
      sign_in_as(student)
      group.repo_accesses << RepoAccess.create!(user: student, organization: organization)
      @group_assignment_repo = GroupAssignmentRepo.create!(group_assignment: group_assignment, group: group)
    end

    after(:each) do
      RepoAccess.destroy_all
      Group.destroy_all
      GroupAssignmentRepo.destroy_all
    end

    context "delete github repository after accepting a invitation successfully", :vcr do
      before do
        organization.github_client.delete_repository(@group_assignment_repo.github_repo_id)
        get :successful_invitation, params: { id: invitation.key }
      end

      it "deletes the old group assignment repo" do
        expect { @group_assignment_repo.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "creates a new group assignment repo for the group" do
        expect(GroupAssignmentRepo.last.id).not_to eq(@group_assignment_repo.id)
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
