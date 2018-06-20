# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orgs::RostersController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }
  let(:roster)       { create(:roster)   }
  let(:entry)        { roster.roster_entries.first }

  before(:each) do
    organization.update_attributes!(roster_id: roster.id)
  end

  describe "GET #new", :vcr do
    context "with flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      it "succeeds" do
        sign_in_as(user)
        get :new, params: { id: organization.slug }
        expect(response).to have_http_status(:success)
      end

      it "renders correct template" do
        sign_in_as(user)
        get :new, params: { id: organization.slug }
        expect(response).to render_template("rosters/new")
      end

      it "redirects if the user doesn't belong to the organization" do
        sign_in_as(classroom_student)

        get :new, params: { id: organization.slug }
        expect(response).to have_http_status(:redirect)
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        sign_in_as(user)
        get :new, params: { id: organization.slug }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #create", :vcr do
    before do
      sign_in_as(user)
    end

    context "with flipper enabled" do
      before(:each) do
        Roster.destroy_all
      end

      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      it "sends an event to statsd" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("roster.create")

        post :create, params: {
          id: organization.slug,
          identifiers: "email1\r\nemail2",
          identifier_name: "emails"
        }
      end

      context "with no identifier_name" do
        before do
          post :create, params: { id: organization.slug, identifiers: "myemail" }
        end

        it "renders new" do
          expect(response).to render_template("rosters/new")
        end

        it "does not create any rosters" do
          expect(Roster.count).to eq(0)
        end
      end

      context "with identifier_name" do
        context "with valid identifiers" do
          before do
            organization.update_attributes(roster_id: nil)
            Roster.destroy_all
            RosterEntry.destroy_all

            post :create, params: {
              id: organization.slug,
              identifiers: "email1\r\nemail2",
              identifier_name: "emails"
            }

            @roster = organization.reload.roster
            @roster_entries = @roster.roster_entries
          end

          it "redirects to organization path" do
            expect(response).to redirect_to(organization_url(organization))
          end

          it "creates one roster with correct identifier_name" do
            expect(Roster.count).to eq(1)
            expect(@roster.identifier_name).to eq("emails")
          end

          it "creates two roster_entries" do
            expect(RosterEntry.count).to eq(2)
          end

          it "creates roster_entries with correct identifier" do
            expect(@roster_entries.map(&:identifier)).to match_array(%w[email1 email2])
          end

          it "sets flash[:success]" do
            expect(flash[:success]).to be_present
          end
        end

        context "with an empty set of identifiers" do
          before do
            post :create, params: {
              id: organization.slug,
              identifiers: "    \r\n ",
              identifier_name: "emails"
            }

            @roster = Roster.first
          end

          it "does not create a roster" do
            expect(@roster).to be_nil
          end

          it "renders :new" do
            expect(response).to render_template("rosters/new")
          end
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        post :create, params: { id: organization.slug }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #show", :vcr do
    before do
      sign_in_as(user)
    end

    context "with flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
        organization.update_attributes!(roster_id: nil)
      end

      context "with no roster" do
        before do
          get :show, params: { id: organization.slug }
        end

        it "redirects to roster/new" do
          expect(response).to redirect_to(new_roster_url(organization))
        end
      end

      context "with a roster" do
        before do
          organization.roster = create(:roster)
          organization.save

          get :show, params: { id: organization.slug }
        end

        it "succeeds" do
          expect(response).to have_http_status(:success)
        end

        it "renders roster/show" do
          expect(response).to render_template("rosters/show")
        end
      end

      context "download roster button" do
        before do
          roster.roster_entries.destroy_all

          Array.new(24) do |e|
            roster.roster_entries << RosterEntry.new(identifier: "ID-#{e}")
          end
          @all_entries = roster.roster_entries
        end

        it "should exports CSV with all entries" do
          roster_csv = @all_entries.to_csv
          paginated_roster_csv = @all_entries.first(20).to_csv

          expect(paginated_roster_csv.split("\n").size - 1).not_to eq(@all_entries.count)
          expect(roster_csv.split("\n").size - 1).to eq(@all_entries.count)
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        get :show, params: { id: organization.slug }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH #link", :vcr do
    before do
      sign_in_as(user)
    end

    context "with flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "user and entry exist" do
        before do
          # Create an unlinked user
          assignment = create(:assignment, organization: organization)
          create(:assignment_repo, assignment: assignment, user: user)

          patch :link, params: {
            id:              organization.slug,
            user_id:         user.id,
            roster_entry_id: entry.id
          }
        end

        it "redirects to #show" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "creates link" do
          expect(entry.reload.user).to eq(user)
        end
      end

      context "user/link does not exist" do
        before do
          patch :link, params: {
            id:              organization.slug,
            user_id:         3,
            roster_entry_id: entry.id
          }
        end

        it "redirects to #show" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "does not create a link" do
          expect(entry.reload.user).to be_nil
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        patch :link, params: {
          id:              organization.slug,
          user_id:         3,
          roster_entry_id: 2
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH #unlink", :vcr do
    before do
      sign_in_as(user)
    end

    context "with flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "with a linked entry" do
        before do
          entry.user = user
          entry.save

          patch :unlink, params: {
            id:              organization.slug,
            roster_entry_id: entry.id
          }
        end

        it "redirects to roster page" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "unlinks entry and user" do
          expect(entry.reload.user).to be_nil
        end
      end

      context "with an unlinked entry" do
        before do
          entry.user = nil
          entry.save

          patch :unlink, params: {
            id:              organization.slug,
            roster_entry_id: entry.id
          }
        end

        it "redirects to roster page" do
          expect(response).to redirect_to(roster_url(organization))
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        patch :unlink, params: {
          id:              organization.slug,
          roster_entry_id: entry.id
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH #add_students", :vcr do
    before do
      sign_in_as(user)
    end

    context "with flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "when all identifiers are valid" do
        before do
          patch :add_students, params: {
            id:         organization.slug,
            identifiers: "a\r\nb"
          }
        end

        it "redirects to rosters page" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "sets success message" do
          expect(flash[:success]).to eq("Students created.")
        end

        it "creates the student on the roster" do
          expect(roster.reload.roster_entries).to include(RosterEntry.find_by(identifier: "a"))
        end
      end

      context "when some identifiers get added" do
        before do
          create(:roster_entry, roster: roster, identifier: "a")
          patch :add_students, params: {
            id:         organization.slug,
            identifiers: "a\r\nb"
          }
        end

        it "redirects to rosters page" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "sets flash message" do
          expect(flash[:success]).to eq("Students created. Some duplicates have been omitted.")
        end

        it "creates only one roster entry" do
          expect do
            patch :add_students, params: {
              id:         organization.slug,
              identifiers: "a\r\nc"
            }
          end.to change(roster.reload.roster_entries, :count).by(1)
        end
      end

      context "when no identifiers get added" do
        before do
          create(:roster_entry, roster: roster, identifier: "a")
          create(:roster_entry, roster: roster, identifier: "b")
          patch :add_students, params: {
            id:         organization.slug,
            identifiers: "a\r\nb"
          }
        end

        it "redirects to rosters page" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "sets flash message" do
          expect(flash[:warning]).to eq("No students created.")
        end

        it "creates no roster entries" do
          expect do
            patch :add_students, params: {
              id:         organization.slug,
              identifiers: "a\r\nb"
            }
          end.to change(roster.reload.roster_entries, :count).by(0)
        end
      end

      context "when there's an internal error" do
        before do
          errored_entry = RosterEntry.new(roster: roster)
          errored_entry.errors[:base] << "Something went wrong ¯\\_(ツ)_/¯ "
          allow(RosterEntry).to receive(:create).and_return(errored_entry)

          patch :add_students, params: {
            id:         organization.slug,
            identifiers: "a\r\nb"
          }
        end

        it "redirects to rosters page" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "sets flash message" do
          expect(flash[:error]).to eq("An error has occured. Please try again.")
        end

        it "creates no roster entries" do
          expect do
            patch :add_students, params: {
              id:         organization.slug,
              identifiers: "a\r\nb"
            }
          end.to change(roster.reload.roster_entries, :count).by(0)
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        patch :add_students, params: {
          id:         organization.slug,
          identifier: "Hello"
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH #delete_entry", :vcr do
    before do
      sign_in_as(user)
    end

    context "with flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "when there is 1 entry in the roster" do
        before do
          patch :delete_entry, params: {
            id: organization.slug,
            roster_entry_id: entry.id
          }
        end

        it "redirects to roster page" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "does not remove the roster entry from the roster" do
          expect(roster.roster_entries.length).to eq(1)
        end

        it "displays error message" do
          expect(flash[:error]).to_not be_nil
        end
      end

      context "when there are more than 1 entry in the roster" do
        before(:each) do
          @second_entry = create(:roster_entry, roster: roster)
          roster.reload

          patch :delete_entry, params: {
            roster_entry_id: entry.id,
            id:              organization.slug
          }
        end

        it "redirects to roster page" do
          expect(response).to redirect_to(roster_url(organization))
        end

        it "removes the roster entry from the roster" do
          expect(roster.reload.roster_entries).to eq([@second_entry])
        end

        it "displays success message" do
          expect(flash[:success]).to_not be_nil
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        patch :delete_entry, params: {
          roster_entry_id: entry.id,
          id:              organization.slug
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH #remove_organization", :vcr do
    before do
      sign_in_as(user)
    end

    context "with flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable

        roster.organizations << organization
      end

      context "when there are multiple organizations in the roster" do
        before do
          roster.organizations << create(:organization)

          patch :remove_organization, params: {
            id: organization.slug
          }
        end

        it "does not destroy the organization" do
          expect(Roster.find_by(id: roster.id)).to be_truthy
        end

        it "removes organization from roster" do
          expect(roster.reload.organizations).to_not include(organization)
        end

        it "renders success message" do
          expect(flash[:success]).to be_present
        end

        it "redirects to organization path" do
          expect(response).to redirect_to(organization_path(organization))
        end
      end

      context "when there is one organization in the roster" do
        before do
          patch :remove_organization, params: {
            id: organization.slug
          }
        end

        it "destroys the roster" do
          expect(Roster.find_by(id: roster.id)).to be_falsey
        end

        it "nullifies organization.roster" do
          expect(organization.reload.roster).to be_nil
        end

        it "renders success message" do
          expect(flash[:success]).to be_present
        end

        it "redirects to organization path" do
          expect(response).to redirect_to(organization_path(organization))
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        patch :remove_organization, params: {
          id: organization.slug
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
