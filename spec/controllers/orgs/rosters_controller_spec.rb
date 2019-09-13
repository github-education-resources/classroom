# frozen_string_literal: true

require "rails_helper"
require "signet/oauth_2/client"
require "google/apis/classroom_v1"

RSpec.describe Orgs::RostersController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }
  let(:roster)       { create(:roster)   }
  let(:entry)        { roster.roster_entries.first }

  before(:each) do
    organization.update_attributes!(roster_id: roster.id)
  end

  describe "GET #new", :vcr do
    before do
      organization.update_attributes!(roster_id: nil)
    end

    after do
      organization.update_attributes(roster_id: roster.id)
    end

    it "succeeds" do
      sign_in_as(user)
      get :new, params: { id: organization.slug }
      expect(response).to have_http_status(200)
    end

    it "renders correct template" do
      sign_in_as(user)
      get :new, params: { id: organization.slug }
      expect(response).to render_template("rosters/new")
    end

    it "sends not found if the user doesn't belong to the organization" do
      sign_in_as(classroom_student)

      get :new, params: { id: organization.slug }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create", :vcr do
    before do
      sign_in_as(user)
    end

    before(:each) do
      Roster.destroy_all
    end

    it "sends an event to statsd" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("roster.create")

      post :create, params: {
        id: organization.slug,
        identifiers: "email1\r\nemail2",
        identifier_name: "emails"
      }
    end

    context "when there is an lti_configuration present" do
      before(:each) do
        create(:lti_configuration, organization: organization)
      end

      it "sends statsd" do
        allow(GitHubClassroom.statsd).to receive(:increment)
        post :create, params: {
          id:         organization.slug,
          identifier_name: "emails",
          identifiers: "a\r\nb",
          lms_user_ids: [1, 2]
        }
        expect(GitHubClassroom.statsd).to have_received(:increment).with("lti_configuration.import")
        expect(GitHubClassroom.statsd).to have_received(:increment).with("roster_entries.lms_imported", by: 2)
      end

      it "creates roster entries" do
        post :create, params: {
          id:         organization.slug,
          identifier_name: "emails",
          identifiers: "a\r\nb",
          lms_user_ids: "1 2"
        }
        organization.reload
        expect(organization.roster.roster_entries.count).to eq(2)
        expect(organization.roster.roster_entries[0].lms_user_id).to eq("1")
        expect(organization.roster.roster_entries[1].lms_user_id).to eq("2")
      end

      context "failbot reports when there is an error" do
        before do
          allow_any_instance_of(Orgs::RostersController)
            .to receive(:lms_membership)
            .and_raise(Faraday::ClientError)
          Failbot.reports.clear
        end

        it "successfully" do
          post :create, params: {
            id: organization.slug,
            identifiers: "email1\r\nemail2",
            identifier_name: "emails"
          }
          expect(Failbot.reports.count).to eq(1)
        end

        after do
          Failbot.reports.clear
        end
      end

      after(:each) do
        Roster.destroy_all
        RosterEntry.destroy_all
      end
    end

    context "with no identifier_name" do
      before do
        post :create, params: { id: organization.slug, identifiers: "myemail" }
      end

      it "it creates roster" do
        expect(Roster.count).to eq(1)
      end

      it "redirects user to organization#show" do
        expect(response).to redirect_to(organization_path)
        expect(flash[:success]).to be_present
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
  end

  describe "GET #show", :vcr do
    before do
      sign_in_as(user)
    end

    before do
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
        expect(response).to have_http_status(200)
      end

      it "renders roster/show" do
        expect(response).to render_template("rosters/show")
      end
    end

    context "download roster button" do
      before do
        organization.roster = create(:roster)
        organization.save

        Array.new(24) do |e|
          organization.roster.roster_entries << RosterEntry.new(identifier: "ID-#{e}")
        end
        @all_entries = organization.roster.roster_entries
      end

      it "should export CSV with all entries" do
        get :show, params: { id: organization.slug, format: "csv" }

        csv = response.body.split("\n")
        csv_without_header = csv[1..-1]

        expect(csv_without_header.length).to eq(@all_entries.count)
      end

      it "succeeds when accessible grouping is provided" do
        grouping = create(:grouping, organization: organization)

        get :show, params: { id: organization.slug, grouping: grouping.id, format: "csv" }

        csv = response.body.split("\n")
        csv_without_header = csv[1..-1]

        expect(csv_without_header.length).to eq(@all_entries.count)
      end

      it "404s when inaccessible grouping is provided" do
        grouping = create(:grouping)

        get :show, params: { id: organization.slug, grouping: grouping.id, format: "csv" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #import_lms_roster", :vcr do
    before do
      sign_in_as(user)
    end

    context "with existing LMS" do
      let(:lti_configuration) { create(:lti_configuration, organization: organization) }

      context "with context_membership_url" do
        before(:each) do
          LtiConfiguration
            .any_instance
            .stub(:supports_membership_service?)
            .and_return(true)
        end

        context "fetching roster succeeds" do
          let(:student) do
            GitHubClassroom::LTI::Models::CourseMember.new(
              email: "sample@example.com",
              name: "Example Name",
              user_id: "12345"
            )
          end

          let(:students) do
            [student]
          end

          before(:each) do
            GitHubClassroom::LTI::MembershipService
              .any_instance
              .stub(:students)
              .and_return(students)
          end

          context "all attributes present" do
            it "format.html: succeeds" do
              get :import_from_lms, params: { id: lti_configuration.organization.slug }
              expect(response).to have_http_status(:ok)
              expect(flash[:alert]).to be_nil
              expect(assigns(:identifiers).keys.length).to eql(3)
            end

            it "format.js: succeeds" do
              get :import_from_lms, format: :js, xhr: true, params: { id: lti_configuration.organization.slug }
              expect(response).to have_http_status(:ok)
              expect(flash[:alert]).to be_nil
              expect(assigns(:identifiers).keys.length).to eql(3)
            end

            context "no new students" do
              before(:each) do
                subject
                  .stub(:filter_new_students)
                  .and_return([])
              end

              it "creates no duplicate entries" do
                expect(subject).to receive(:handle_lms_import_error)

                get :import_from_lms, params: { id: lti_configuration.organization.slug }
              end
            end
          end

          context "successful fetch, but missing some attributes" do
            let(:student) do
              GitHubClassroom::LTI::Models::CourseMember.new(
                email: nil,
                name: nil,
                user_id: "12345"
              )
            end

            it "hides options when they're nil lists" do
              get :import_from_lms, params: { id: lti_configuration.organization.slug }
              expect(response).to have_http_status(:ok)
              expect(assigns(:identifiers).keys.length).to eql(1)
            end
          end
        end

        context "fetching roster fails" do
          before(:each) do
            GitHubClassroom::LTI::MembershipService
              .any_instance
              .stub(:students)
              .and_raise(JSON::ParserError)
          end

          it "format.html: presents an error message to the user" do
            get :import_from_lms, params: { id: lti_configuration.organization.slug }
            expect(flash[:alert]).to be_present
          end

          it "format.js: presents an error message to the user" do
            get :import_from_lms, format: :js, xhr: true, params: { id: lti_configuration.organization.slug }
            expect(response.status).to be(422)
            expect(flash[:alert]).to be_present
          end
        end
      end

      context "without context_membership_service_url" do
        it "format.html: presents an error message to the user" do
          get :import_from_lms, params: { id: lti_configuration.organization.slug }
          expect(flash[:alert]).to be_present
        end

        it "format.js: presents an error message to the user" do
          get :import_from_lms, format: :js, xhr: true, params: { id: lti_configuration.organization.slug }
          expect(response.status).to be(422)
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "with no existing LMS" do
      it "Redirects to link LTI configuration page" do
        get :import_from_lms, params: { id: organization.slug }
        expect(response).to redirect_to(link_lms_organization_path)
      end
    end
  end

  describe "PATCH #link", :vcr do
    before do
      sign_in_as(user)
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
  end

  describe "PATCH #unlink", :vcr do
    before do
      sign_in_as(user)
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
  end

  describe "PATCH #add_students", :vcr do
    before do
      sign_in_as(user)
    end

    context "with google or lti integration" do
      context "sends out statsd when successful" do
        before do
          create(:lti_configuration, organization: organization)
        end

        it "sends successfully" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("roster_entries.lms_imported", by: 2)
          patch :add_students, params: {
            id:         organization.slug,
            identifiers: "a\r\nb",
            lms_user_ids: [1, 2]
          }
        end
      end

      context "does not send out statsd when not successful" do
        before do
          Roster.destroy_all
          RosterEntry.destroy_all
        end

        it "sends successfully" do
          expect(GitHubClassroom.statsd).to_not receive(:increment).with("roster_entries.lms_imported", by: 2)
          patch :add_students, params: {
            id:         organization.slug,
            identifiers: "a\r\nb",
            lms_user_ids: [1, 2]
          }
        end
      end
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

    context "when there are duplicate identifiers" do
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
        expect(flash[:success]).to eq("Students created.")
      end

      it "creates roster entries" do
        expect do
          patch :add_students, params: {
            id:         organization.slug,
            identifiers: "a\r\nb"
          }
        end.to change(roster.reload.roster_entries, :count).by(2)
      end

      it "finds identifiers with suffix" do
        expect(roster.reload.roster_entries).to include(RosterEntry.find_by(identifier: "a-1"))
        expect(roster.reload.roster_entries).to include(RosterEntry.find_by(identifier: "b-1"))
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
        expect(flash[:error]).to eq("An error has occurred. Please try again.")
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
  end

  describe "PATCH #delete_entry", :vcr do
    before do
      sign_in_as(user)
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
  end

  describe "PATCH #edit_entry", :vcr do
    before do
      sign_in_as(user)

      create(:roster_entry, roster: roster, identifier: "John Smith")
      create(:roster_entry, roster: roster, identifier: "John Smith-1")
    end

    context "when renaming to an identifier that does not exist" do
      before do
        patch :edit_entry, params: {
          roster_entry_id: organization.roster.roster_entries.second,
          roster_entry_identifier: "Jessica Smith",
          id: organization.slug
        }
        organization.reload.roster.roster_entries
      end

      it "updates roster entry" do
        expect(organization.roster.roster_entries.second.identifier).to eq("Jessica Smith")
      end

      it "redirects to roster page" do
        expect(response).to redirect_to(roster_url(organization))
      end

      it "displays success message" do
        expect(flash[:success]).to eq("Roster entry successfully updated!")
      end
    end

    context "when renaming to an identifier that exists" do
      before do
        patch :edit_entry, params: {
          roster_entry_id: organization.roster.roster_entries.second,
          roster_entry_identifier: "John Smith-1",
          id: organization.slug
        }
      end

      it "does not update roster entry" do
        expect(organization.roster.roster_entries.second.identifier).to eq("John Smith")
      end

      it "redirects to roster page" do
        expect(response).to redirect_to(roster_url(organization))
      end

      it "displays success message" do
        expect(flash[:error]).to eq("There is already a roster entry named John Smith-1.")
      end
    end
  end

  describe "PATCH #remove_organization", :vcr do
    before do
      sign_in_as(user)
    end

    before do
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
  end

  describe "PATCH #import_from_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "when google classroom course is linked" do
      before do
        organization.update_attributes(google_course_id: "1234")
      end

      context "when user is authorized with google" do
        before do
          # Stub google authentication
          client = Signet::OAuth2::Client.new
          allow_any_instance_of(ApplicationController)
            .to receive(:user_google_classroom_credentials)
            .and_return(client)
        end

        context "when course has multiple students" do
          before do
            valid_response = GoogleAPI::ListStudentsResponse.new

            student_names = ["Student 1", "Student 2"]
            student_profiles = student_names.map do |name|
              GoogleAPI::UserProfile.new(name: GoogleAPI::Name.new(full_name: name))
            end
            students = student_profiles.map { |prof| GoogleAPI::Student.new(profile: prof) }

            valid_response.students = students
            allow_any_instance_of(GoogleAPI::ClassroomService)
              .to receive(:list_course_students)
              .and_return(valid_response)
          end

          context "when organization has no roster" do
            before do
              organization.update_attributes(roster_id: nil)
            end

            it "sends statsd" do
              allow(GitHubClassroom.statsd).to receive(:increment)
              patch :import_from_google_classroom, params: {
                id: organization.slug
              }
              expect(GitHubClassroom.statsd).to have_received(:increment).with("google_classroom.import")
              expect(GitHubClassroom.statsd).to have_received(:increment).with("roster_entries.lms_imported", by: 2)
            end

            context "when students are fetched succesfully" do
              before do
                patch :import_from_google_classroom, params: {
                  id: organization.slug
                }
              end

              it "sets success message" do
                expect(flash[:success]).to start_with("Your classroom roster has been saved! Manage it")
              end

              it "has correct number of students" do
                expect(organization.reload.roster.roster_entries.count).to eq(2)
              end

              it "has students with correct names" do
                expect(organization.reload.roster.roster_entries[0]).to have_attributes(identifier: "Student 1")
                expect(organization.reload.roster.roster_entries[1]).to have_attributes(identifier: "Student 2")
              end

              it "links the google classroom to the organization" do
                expect(organization.reload.google_course_id).to eq("1234")
              end
            end

            context "when there is an error fetching students" do
              before do
                allow_any_instance_of(GoogleAPI::ClassroomService)
                  .to receive(:list_course_students)
                  .and_raise(Google::Apis::ServerError.new("boom"))

                patch :import_from_google_classroom, params: {
                  id: organization.slug
                }
              end

              it "sets error message" do
                expect(flash[:error]).to eq("Failed to fetch students from Google Classroom. Please try again later.")
              end
            end
          end
        end
      end
    end

    context "when there is no google classroom course linked" do
      context "when user is authorized with google" do
        before do
          # Stub google authentication
          client = Signet::OAuth2::Client.new
          allow_any_instance_of(ApplicationController)
            .to receive(:user_google_classroom_credentials)
            .and_return(client)
        end

        it "redirects to google classroom selection route" do
          patch :import_from_google_classroom, params: {
            id: organization.slug
          }
          expect(response).to redirect_to(google_classrooms_index_organization_path(organization))
        end

        it "sets flash message" do
          patch :import_from_google_classroom, params: {
            id: organization.slug
          }
          expect(flash[:alert]).to eq(
            "Please link a Google Classroom before syncing a roster."
          )
        end
      end
    end
  end

  describe "PATCH #sync_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "when user is authorized with google" do
      before do
        # Stub google authentication again
        client = Signet::OAuth2::Client.new
        allow_any_instance_of(ApplicationController)
          .to receive(:user_google_classroom_credentials)
          .and_return(client)
      end

      context "classroom has a linked google course" do
        before do
          organization.update_attributes(google_course_id: "1234")

          student_names = ["Student 1", "Student 2"]
          student_profiles = student_names.map do |name|
            GoogleAPI::UserProfile.new(name: GoogleAPI::Name.new(full_name: name))
          end
          @students = student_profiles.map do |prof|
            GoogleAPI::Student.new(profile: prof, user_id: SecureRandom.uuid)
          end

          allow_any_instance_of(GoogleClassroomCourse)
            .to receive(:students)
            .and_return(@students)

          patch :sync_google_classroom, params: { id: organization.slug }
        end

        it "adds the new student to the roster" do
          expect(organization.roster.roster_entries.count).to eq(3)
        end

        it "does not add duplicate students that were already added to roster" do
          patch :sync_google_classroom, params: { id: organization.slug }
          expect(organization.roster.roster_entries.count).to eq(3)
        end

        it "does not remove students deleted from google classroom" do
          allow_any_instance_of(GoogleClassroomCourse)
            .to receive(:students)
            .and_return([])

          patch :sync_google_classroom, params: { id: organization.slug }
          expect(organization.roster.roster_entries.count).to eq(3)
        end
      end

      context "when there is no google classroom course linked" do
        before do
          patch :import_from_google_classroom, params: {
            id: organization.slug
          }
        end

        it "redirects to google classroom selection route" do
          expect(response).to redirect_to(google_classrooms_index_organization_path(organization))
        end

        it "sets flash message" do
          expect(flash[:alert]).to eq(
            "Please link a Google Classroom before syncing a roster."
          )
        end
      end

      context "when user is not authorized with google" do
        before do
          allow_any_instance_of(ApplicationController)
            .to receive(:user_google_classroom_credentials)
            .and_return(nil)

          patch :sync_google_classroom, params: { id: organization.slug }
        end

        it "redirects to authorization url" do
          expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
        end
      end
    end
  end
end
