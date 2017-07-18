# frozen_string_literal: true

require "rails_helper"

RSpec.describe RostersController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }
  let(:roster)       { create(:roster) }
  let(:entry)        { create(:roster_entry, roster: roster) }

  describe "GET #new", :vcr do
    before do
      sign_in_as(user)
    end

    context "with flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable

        get :new, params: { id: organization.slug }
      end

      it "succeeds" do
        expect(response).to have_http_status(:success)
      end

      it "renders correct template" do
        expect(response).to render_template("rosters/new")
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
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
            post :create, params: {
              id: organization.slug,
              identifiers: "email1\r\nemail2",
              identifier_name: "emails"
            }

            @roster = Roster.first
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
            expect(@roster_entries[0].identifier).to eq("email1")
            expect(@roster_entries[1].identifier).to eq("email2")
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
end
