# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentsController, type: :controller do
  let(:organization) { classroom_org                                   }
  let(:user)         { classroom_teacher                               }
  let(:assignment)   { create(:assignment, organization: organization) }

  before do
    sign_in_as(user)
  end

  describe "GET #new", :vcr do
    it "returns success status" do
      get :new, params: { organization_id: organization.slug }
      expect(response).to have_http_status(:success)
    end

    it "has a new Assignment" do
      get :new, params: { organization_id: organization.slug }
      expect(assigns(:assignment)).to_not be_nil
    end
  end

  describe "POST #create", :vcr do
    it "creates a new Assignment" do
      expect do
        post :create, params: {
          assignment: attributes_for(:assignment, organization: organization),
          organization_id: organization.slug
        }
      end.to change(Assignment, :count)
    end

    it "sends an event to statsd" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("exercise.create")

      post :create, params: {
        assignment: attributes_for(:assignment, organization: organization),
        organization_id: organization.slug
      }
    end

    context "valid starter_code repo_name input" do
      it "creates a new Assignment" do
        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment, organization: organization),
          repo_name:       "rails/rails"
        }

        expect(Assignment.count).to eql(1)
      end

      it "creates a new Assignment when name has a period" do
        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment, organization: organization),
          repo_name:       "rails/rails.github.com"
        }

        expect(Assignment.count).to eql(1)
      end
    end

    context "invalid starter_code repo_name input" do
      before do
        request.env["HTTP_REFERER"] = "http://test.host/classrooms/new"

        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment, organization: organization),
          repo_name:       "https://github.com/rails/rails"
        }
      end

      it "fails to create a new Assignment" do
        expect(Assignment.count).to eql(0)
      end

      it "does not return an internal server error" do
        expect(response).not_to have_http_status(:internal_server_error)
      end

      it "provides a friendly error message" do
        expect(flash[:error]).to eql("Invalid repository name, use the format owner/name.")
      end
    end

    context "valid repo_id for starter_code is passed" do
      before do
        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment, organization: organization),
          repo_id:         8514 # 'rails/rails'
        }
      end

      it "creates a new Assignment" do
        expect(Assignment.count).to eql(1)
      end

      it "sets correct starter_code_repo for the new Assignment" do
        expect(Assignment.first.starter_code_repo_id).to be(8514)
      end
    end

    context "invalid repo_id for starter_code is passed" do
      before do
        request.env["HTTP_REFERER"] = "http://test.host/classrooms/new"

        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment, organization: organization),
          repo_id:         "invalid_id" # id must be an integer
        }
      end

      it "fails to create a new Assignment" do
        expect(Assignment.count).to eql(0)
      end

      it "does not return an internal server error" do
        expect(response).not_to have_http_status(:internal_server_error)
      end

      it "provides a friendly error message" do
        expect(flash[:error]).to eql("Invalid repository selection, please check it again.")
      end
    end

    context "deadlines" do
      it "sends an event to statsd" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise.create")
        expect(GitHubClassroom.statsd).to receive(:increment).with("deadline.create")

        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment, organization: organization)
            .merge(deadline: "05/25/2100 13:17-0800")
        }
      end

      context "valid datetime for deadline is passed" do
        before do
          post :create, params: {
            organization_id: organization.slug,
            assignment:      attributes_for(:assignment, organization: organization)
              .merge(deadline: "05/25/2100 13:17-0800")
          }
        end

        it "creates a new assignment" do
          expect(Assignment.count).to eq(1)
        end

        it "sets deadline" do
          expect(Assignment.first.deadline).to be_truthy
        end
      end

      context "invalid datetime for deadline passed" do
        before do
          post :create, params: {
            organization_id: organization.slug,
            assignment:      attributes_for(:assignment, organization: organization)
              .merge(deadline: "I am not a datetime")
          }
        end

        it "creates a new assignment" do
          expect(Assignment.count).to eq(1)
        end

        it "sets deadline to nil" do
          expect(Assignment.first.deadline).to be_nil
        end
      end

      context "no deadline passed" do
        before do
          post :create, params: {
            organization_id: organization.slug,
            assignment:      attributes_for(:assignment, organization: organization)
          }
        end

        it "creates a new assignment" do
          expect(Assignment.count).to eq(1)
        end

        it "sets deadline to nil" do
          expect(Assignment.first.deadline).to be_nil
        end
      end
    end
  end

  describe "GET #show", :vcr do
    it "returns success status" do
      get :show, params: { organization_id: organization.slug, id: assignment.slug }
      expect(response).to have_http_status(:success)
    end
  end

  describe "search for user in the roster", :vcr do
    before do
      organization.roster = create(:roster)
      organization.save!
      RosterEntry.create(identifier: "tester", roster: organization.roster)
      organization.roster.reload
      GitHubClassroom.flipper[:search_assignments].enable
    end

    it "finds one user if in roster" do
      get :show, xhr: true, params: { organization_id: organization.slug, id: assignment.slug, query: "tester" }
      expect(response.status).to eq(200)
      expect(assigns(:roster_entries)).to_not eq([])
    end

    it "finds no user if not in roster" do
      get :show, xhr: true, params: { organization_id: organization.slug, id: assignment.slug, query: "aabz" }
      expect(response.status).to eq(200)
      expect(assigns(:roster_entries)).to eq([])
    end

    it "search is not case-sensitive" do
      get :show, xhr: true, params: { organization_id: organization.slug, id: assignment.slug, query: "TESTER" }
      expect(response.status).to eq(200)
      expect(assigns(:roster_entries)).to_not eq([])
    end
  end

  describe "display student username", :vcr, type: :view do
    before do
      organization.users.push(create(:user, uid: 90, token: "asdfsad4333"))
      organization.roster = create(:roster)
      organization.roster.roster_entries.push(RosterEntry.create(
                                                identifier: "student",
                                                roster: organization.roster,
                                                user_id: organization.users.last
      ))
      organization.save!
      organization.roster.reload
    end

    it "displays student's identifier if is a roster_entry" do
      assignment_repo = create(:assignment_repo,
        assignment: assignment,
        user: organization.users.last,
        github_repo_id: 34_534_534)
      render partial: "orgs/roster_entries/assignment_repos/linked_accepted",
             locals: { assignment_repo: assignment_repo,
                       current_roster_entry: organization.roster.roster_entries.last }
      expect(response).to include("student")
    end

    it "displays student github username if there is no roster_entry" do
      assignment_repo = create(:assignment_repo,
        assignment: assignment,
        user: organization.users.last,
        github_repo_id: 34_534_534)
      render partial: "orgs/roster_entries/assignment_repos/linked_accepted",
             locals: { assignment_repo: assignment_repo }
      expect(response).to_not include("student")
    end
  end

  describe "GET #edit", :vcr do
    it "returns success and sets the assignment" do
      get :edit, params: { id: assignment.slug, organization_id: organization.slug }

      expect(response).to have_http_status(:success)
      expect(assigns(:assignment)).to_not be_nil
    end
  end

  describe "PATCH #update", :vcr do
    it "correctly updates the assignment" do
      options = { title: "Ruby on Rails" }
      patch :update, params: { id: assignment.slug, organization_id: organization.slug, assignment: options }

      expect(response).to redirect_to(organization_assignment_path(organization, Assignment.find(assignment.id)))
    end

    context "public_repo is changed" do
      it "calls the AssignmentVisibility background job" do
        private_repos_plan = { owned_private_repos: 0, private_repos: 2 }
        options = { title: "Ruby on Rails", public_repo: !assignment.public? }

        allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(private_repos_plan)

        assert_enqueued_jobs 1, only: Assignment::RepositoryVisibilityJob do
          patch :update, params: { id: assignment.slug, organization_id: organization.slug, assignment: options }
        end
      end
    end

    context "public_repo is not changed" do
      it "will not kick off an AssignmentVisibility job" do
        options = { title: "Ruby on Rails" }

        assert_no_enqueued_jobs only: Assignment::RepositoryVisibilityJob do
          patch :update, params: { id: assignment.slug, organization_id: organization.slug, assignment: options }
        end
      end
    end

    context "slug is empty" do
      it "correctly reloads the assignment" do
        options = { slug: "" }
        patch :update, params: { id: assignment.slug, organization_id: organization.slug, assignment: options }

        expect(assigns(:assignment).slug).to_not be_nil
      end
    end
  end

  describe "DELETE #destroy", :vcr do
    it "sets the `deleted_at` column for the assignment" do
      assignment

      expect do
        delete :destroy, params: { id: assignment.slug, organization_id: organization }
      end.to change(Assignment, :count)

      expect(Assignment.unscoped.find(assignment.id).deleted_at).not_to be_nil
    end

    it "calls the DestroyResource background job" do
      delete :destroy, params: { id: assignment.slug, organization_id: organization }

      assert_enqueued_jobs 1 do
        DestroyResourceJob.perform_later(assignment)
      end
    end

    it "sends an event to statsd" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("exercise.destroy")

      delete :destroy, params: { id: assignment.slug, organization_id: organization }
    end

    it "redirects back to the organization" do
      delete :destroy, params: { id: assignment.slug, organization_id: organization.slug }
      expect(response).to redirect_to(organization)
    end
  end
end
