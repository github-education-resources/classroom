# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orgs::RosterEntriesController, type: :controller do
  let(:roster) { create(:roster) }
  let(:roster_entry) { roster.roster_entries.first }
  let(:organization) { create(:organization, roster: roster, github_id: 1000) }
  let(:assignment) { create(:assignment, organization: organization) }
  let(:student) { classroom_student }
  let(:teacher) { classroom_teacher }

  describe "GET #show", :vcr do
    context "when not logged in" do
      before do
        sign_out

        get :show, params: {
          organization_id: organization.slug,
          assignment_id: assignment.slug,
          roster_entry_id: roster_entry.id
        }
      end

      it "redirects to login_path" do
        expect(response).to redirect_to(login_path)
      end
    end

    context "when not authorized to view organization" do
      before do
        sign_in_as(student)

        get :show, params: {
          organization_id: organization.slug,
          assignment_id: assignment.slug,
          roster_entry_id: roster_entry.id
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authorized" do
      before do
        organization.users << teacher
        organization.save

        sign_in_as(teacher)
      end

      context "when user is not in classroom" do
        before do
          get :show, params: {
            organization_id: organization.slug,
            assignment_id: assignment.slug,
            roster_entry_id: roster_entry.id
          }
        end

        it "returns success" do
          expect(response).to have_http_status(:success)
        end

        it "renders not_in_classroom" do
          expect(response).to render_template("orgs/roster_entries/assignment_repos/_not_in_classroom")
        end
      end

      context "when user is in classroom but has not accepted assignment" do
        before do
          roster_entry.user = student
          roster_entry.save

          get :show, params: {
            organization_id: organization.slug,
            assignment_id: assignment.slug,
            roster_entry_id: roster_entry.id
          }
        end

        it "returns success" do
          expect(response).to have_http_status(:success)
        end

        it "renders not_accepted" do
          expect(response).to render_template("orgs/roster_entries/assignment_repos/_linked_not_accepted")
        end
      end

      context "when user is in classroom and has accepted assignment" do
        before do
          roster_entry.user = student
          roster_entry.save

          create(:assignment_repo, user: student, assignment: assignment)

          get :show, params: {
            organization_id: organization.slug,
            assignment_id: assignment.slug,
            roster_entry_id: roster_entry.id
          }
        end

        it "returns success" do
          expect(response).to have_http_status(:success)
        end

        it "renders not_accepted" do
          expect(response).to render_template("orgs/roster_entries/assignment_repos/_linked_accepted")
        end
      end
    end
  end
end
