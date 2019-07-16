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
      expect(response).to have_http_status(:success)
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
        expect(response).to have_http_status(:success)
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

  describe "GET #select_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "with student identifier flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "with google classroom flipper enabled" do
        before do
          GitHubClassroom.flipper[:google_classroom_roster_import].enable
        end

        context "when user is authorized with google" do
          before do
            # Stub google authentication again
            client = Signet::OAuth2::Client.new
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(client)

            # Stub list courses response
            response = GoogleAPI::ListCoursesResponse.new
            allow_any_instance_of(GoogleAPI::ClassroomService)
              .to receive(:list_courses)
              .and_return(response)

            get :select_google_classroom, params: {
              id: organization.slug
            }
          end

          it "succeeds" do
            expect(response).to have_http_status(:success)
          end
        end

        context "when there is an exixting lti configuration" do
          before do
            create(:lti_configuration,
              organization: organization,
              consumer_key: "hello",
              shared_secret: "hello"
            )
            get :select_google_classroom, params: {
              id: organization.slug
            }
          end

          it "alerts user that there is an exisiting config" do
            expect(response).to redirect_to(edit_organization_path(organization))
            expect(flash[:alert]).to eq(
              "An existing configuration exists. Please remove configuration before creating a new one."
            )
          end
        end

        context "when user is not authorized with google" do
          before do
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(nil)

            get :select_google_classroom, params: {
              id: organization.slug
            }
          end

          it "redirects to authorization url" do
            expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
          end
        end

        after do
          GitHubClassroom.flipper[:google_classroom_roster_import].disable
        end
      end

      context "with google classroom identifier disabled" do
        before do
          get :search_google_classroom, params: {
            id: organization.slug,
            query: ""
          }
        end

        it "404s" do
          expect(response).to have_http_status(:not_found)
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end
  end

  describe "GET #search_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "with student identifier flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "with google classroom flipper enabled" do
        before do
          GitHubClassroom.flipper[:google_classroom_roster_import].enable
        end

        context "when user is authorized with google" do
          before do
            # Stub google authentication again
            client = Signet::OAuth2::Client.new
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(client)

            response = GoogleAPI::ListCoursesResponse.new
            allow_any_instance_of(GoogleAPI::ClassroomService)
              .to receive(:list_courses)
              .and_return(response)
          end

          it "renders google classroom collection partial" do
            request = get :search_google_classroom, params: {
              id: organization.slug,
              query: "git"
            }
            expect(request).to render_template(partial: "orgs/rosters/_google_classroom_collection")
          end
        end

        context "when there is an exixting lti configuration" do
          before do
            create(:lti_configuration,
              organization: organization,
              consumer_key: "hello",
              shared_secret: "hello"
            )
            get :search_google_classroom, params: {
              id: organization.slug,
              query: ""
            }
          end

          it "alerts user that there is an exisiting config" do
            expect(response).to redirect_to(edit_organization_path(organization))
            expect(flash[:alert]).to eq(
              "An existing configuration exists. Please remove configuration before creating a new one."
            )
          end
        end

        context "when user is not authorized with google" do
          before do
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(nil)

            get :search_google_classroom, params: {
              id: organization.slug,
              query: ""
            }
          end

          it "redirects to authorization url" do
            expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
          end
        end

        after do
          GitHubClassroom.flipper[:google_classroom_roster_import].disable
        end
      end

      context "with google classroom identifier disabled" do
        before do
          get :search_google_classroom, params: {
            id: organization.slug,
            query: ""
          }
        end

        it "404s" do
          expect(response).to have_http_status(:not_found)
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        get :search_google_classroom, params: {
          id: organization.slug,
          query: ""
        }
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

    context "with student identifier flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "with google classroom flipper enabled" do
        before do
          GitHubClassroom.flipper[:google_classroom_roster_import].enable
        end

        context "when user is authorized with google" do
          before do
            # Stub google authentication
            client = Signet::OAuth2::Client.new
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(client)
          end

          context "when there is an error fetching students" do
            before do
              allow_any_instance_of(GoogleAPI::ClassroomService)
                .to receive(:list_course_students)
                .and_raise(Google::Apis::ServerError.new("boom"))

              patch :import_from_google_classroom, params: {
                id: organization.slug,
                course_id: "1234"
              }
            end

            it "sets error message" do
              expect(flash[:error]).to eq("Failed to fetch students from Google Classroom. Please try again later.")
            end

            it "does not link the google classroom to the organization" do
              expect(organization.google_course_id).to_not eq("1234")
            end
          end

          context "when course has no students" do
            before do
              empty_response = GoogleAPI::ListStudentsResponse.new
              empty_response.students = nil
              allow_any_instance_of(GoogleAPI::ClassroomService)
                .to receive(:list_course_students)
                .and_return(empty_response)

              patch :import_from_google_classroom, params: {
                id: organization.slug,
                course_id: "1234"
              }
            end

            it "sets warning message" do
              message = "No students were found in your Google Classroom. Please add students and try again."
              expect(flash[:warning]).to eq(message)
            end

            it "does not link the google classroom to the organization" do
              expect(organization.reload.google_course_id).to_not eq("1234")
            end

            it "redirects to roster path" do
              expect(response).to redirect_to roster_path(organization)
            end
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

            context "when organization already has roster" do
              before do
                patch :import_from_google_classroom, params: {
                  id: organization.slug,
                  course_id: "1234"
                }
              end

              it "sets success message" do
                expect(flash[:success]).to eq("Students created.")
              end

              it "has correct number of students" do
                expect(organization.roster.roster_entries.count).to eq(3)
              end

              it "has students with correct names" do
                expect(organization.roster.roster_entries[1]).to have_attributes(identifier: "Student 1")
                expect(organization.roster.roster_entries[2]).to have_attributes(identifier: "Student 2")
              end

              it "links the google classroom to the organization" do
                expect(organization.reload.google_course_id).to eq("1234")
              end
            end

            context "when organization has no roster" do
              before do
                organization.update_attributes(roster_id: nil)
                patch :import_from_google_classroom, params: {
                  id: organization.slug,
                  course_id: "1234"
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
          end
        end

        context "when there is an exixting lti configuration" do
          before do
            create(:lti_configuration,
              organization: organization,
              consumer_key: "hello",
              shared_secret: "hello"
            )
            patch :import_from_google_classroom, params: {
              id: organization.slug,
              course_id: "1234"
            }
          end

          it "alerts user that there is an exisiting config" do
            expect(response).to redirect_to(edit_organization_path(organization))
            expect(flash[:alert]).to eq(
              "An existing configuration exists. Please remove configuration before creating a new one."
            )
          end
        end

        context "when user is not authorized with google" do
          before do
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(nil)

            patch :import_from_google_classroom, params: {
              id: organization.slug,
              course_id: "1234"
            }
          end

          it "redirects to authorization url" do
            expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
          end
        end

        after do
          GitHubClassroom.flipper[:google_classroom_roster_import].disable
        end
      end

      context "with google classroom identifier disabled" do
        before do
          patch :import_from_google_classroom, params: {
            id: organization.slug,
            course_id: "1234"
          }
        end

        it "404s" do
          expect(response).to have_http_status(:not_found)
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        patch :import_from_google_classroom, params: {
          id: organization.slug,
          course_id: "1234"
        }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH #sync_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "with student identifier flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "with google classroom flipper enabled" do
        before do
          GitHubClassroom.flipper[:google_classroom_roster_import].enable
        end

        context "when user is authorized with google" do
          before do
            # Stub google authentication again
            client = Signet::OAuth2::Client.new
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(client)
          end

          context "classroom has no linked google course id" do
            before do
              patch :sync_google_classroom, params: {
                id: organization.slug
              }
            end

            it "doesn't add any students" do
              expect(organization.roster.roster_entries.count).to eq(1)
            end
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

              allow_any_instance_of(Orgs::RostersController)
                .to receive(:list_google_classroom_students)
                .and_return(@students)

              patch :sync_google_classroom, params: { id: organization.slug }
            end

            it "adds the new student to the roster" do
              expect(organization.roster.roster_entries.count).to eq(3)
            end

            it "deduplicates students that were already added to roster" do
              patch :sync_google_classroom, params: { id: organization.slug }
              expect(organization.roster.roster_entries.count).to eq(3)
            end

            it "does not remove students deleted from google classroom" do
              allow_any_instance_of(Orgs::RostersController)
                .to receive(:list_google_classroom_students)
                .and_return([])

              patch :sync_google_classroom, params: { id: organization.slug }
              expect(organization.roster.roster_entries.count).to eq(3)
            end
          end
        end

        context "when there is an exixting lti configuration" do
          before do
            create(:lti_configuration,
              organization: organization,
              consumer_key: "hello",
              shared_secret: "hello"
            )
            patch :sync_google_classroom, params: {
              id: organization.slug
            }
          end

          it "alerts user that there is an exisiting config" do
            expect(response).to redirect_to(edit_organization_path(organization))
            expect(flash[:alert]).to eq(
              "An existing configuration exists. Please remove configuration before creating a new one."
            )
          end
        end

        context "when user is not authorized with google" do
          before do
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(nil)

            patch :sync_google_classroom, params: { id: organization.slug }
          end

          it "redirects to authorization url" do
            expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
          end
        end

        after do
          GitHubClassroom.flipper[:google_classroom_roster_import].disable
        end
      end

      context "with google classroom identifier disabled" do
        before do
          patch :sync_google_classroom, params: { id: organization.slug }
        end

        it "404s" do
          expect(response).to have_http_status(:not_found)
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        patch :sync_google_classroom, params: { id: organization.slug }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH #unlink_google_classroom", :vcr do
    before do
      sign_in_as(user)
      GoogleAPI = Google::Apis::ClassroomV1
    end

    context "with student identifier flipper enabled" do
      before do
        GitHubClassroom.flipper[:student_identifier].enable
      end

      context "with google classroom flipper enabled" do
        before do
          GitHubClassroom.flipper[:google_classroom_roster_import].enable
        end

        context "when user is authorized with google" do
          before do
            # Stub google authentication again
            client = Signet::OAuth2::Client.new
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(client)

            organization.update_attributes(google_course_id: "1234")

            patch :unlink_google_classroom, params: { id: organization.slug }
          end

          it "removes google course id" do
            expect(organization.reload.google_course_id).to be_nil
          end

          it "flashes success message" do
            message = "Removed link to Google Classroom. No students were removed from your roster."
            expect(flash[:success]).to eq(message)
          end
        end

        context "when there is an exixting lti configuration" do
          before do
            create(:lti_configuration,
              organization: organization,
              consumer_key: "hello",
              shared_secret: "hello"
            )
            patch :unlink_google_classroom, params: { id: organization.slug }
          end

          it "alerts user that there is an exisiting config" do
            expect(response).to redirect_to(edit_organization_path(organization))
            expect(flash[:alert]).to eq(
              "An existing configuration exists. Please remove configuration before creating a new one."
            )
          end
        end

        context "when user is not authorized with google" do
          before do
            allow_any_instance_of(Orgs::RostersController)
              .to receive(:user_google_classroom_credentials)
              .and_return(nil)

            get :search_google_classroom, params: {
              id: organization.slug,
              query: ""
            }
          end

          it "redirects to authorization url" do
            expect(response).to redirect_to %r{\Ahttps://accounts.google.com/o/oauth2}
          end
        end

        after do
          GitHubClassroom.flipper[:google_classroom_roster_import].disable
        end
      end

      context "with google classroom identifier disabled" do
        before do
          get :search_google_classroom, params: {
            id: organization.slug,
            query: ""
          }
        end

        it "404s" do
          expect(response).to have_http_status(:not_found)
        end
      end

      after do
        GitHubClassroom.flipper[:student_identifier].disable
      end
    end

    context "with flipper disabled" do
      before do
        patch :unlink_google_classroom, params: { id: organization.slug }
      end

      it "404s" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
