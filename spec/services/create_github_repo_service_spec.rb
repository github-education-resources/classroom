# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService do
  subject { described_class }
  let(:organization) { classroom_org }
  let(:student)      { classroom_student }
  let(:teacher)      { classroom_teacher }

  describe "for Assignment", :vcr do
    let(:assignment) do
      options = {
        title: "Learn Elm",
        starter_code_repo_id: 1_062_897,
        organization: organization,
        students_are_repo_admins: true,
        public_repo: true
      }

      create(:assignment, options)
    end
    let(:service) { subject.new(assignment, student) }
    describe "#create_github_repository!" do
      it "creates a new github repo" do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:create_repository)
          .with(service.exercise.repo_name, anything)
        service.create_github_repository!
      end
      it "raises a Result::Error" do
        allow_any_instance_of(GitHubOrganization)
          .to receive(:create_repository)
          .and_raise(GitHub::Error, "Could not created GitHub repository")
        expect { service.create_github_repository! }
          .to raise_error(
            subject::Result::Error,
            "GitHub repository could not be created, please try again. (Could not created GitHub repository)"
          )
      end
    end

    describe "#create_github_repository_from_template!" do
      let(:client) { oauth_client }
      let(:github_organization) { GitHubOrganization.new(client, organization.github_id) }

      let(:github_repository) do
        options = {
          private: false,
          is_template: true,
          auto_init: true,
          accept: "application/vnd.github.baptiste-preview"
        }
        github_organization.create_repository("#{Faker::Company.name} Template", options)
      end

      let(:assignment) do
        options = {
          title: "Learn Elm",
          starter_code_repo_id: github_repository.id,
          organization: organization,
          students_are_repo_admins: true,
          public_repo: true,
          template_repos_enabled: true
        }
        create(:assignment, options)
      end

      let(:service) { described_class.new(assignment, student) }

      after(:each) do
        client.delete_repository(github_repository.id)
        AssignmentRepo.destroy_all
      end

      it "sends a request to GitHubOrganization#create_repository_from_template with correct params" do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:create_repository_from_template)
          .with(
            github_repository.id,
            service.exercise.repo_name,
            hash_including(
              private: false,
              description: "#{service.exercise.repo_name} created by GitHub Classroom"
            )
          )
        service.create_github_repository_from_template!
      end

      it "raises a Result::Error if repository not created" do
        allow_any_instance_of(GitHubOrganization)
          .to receive(:create_repository_from_template)
          .and_raise(GitHub::Error, "Could not created GitHub repository")
        expect { service.create_github_repository_from_template! }
          .to raise_error(
            subject::Result::Error,
            "GitHub repository could not be created from template, please try again. (Could not created GitHub repository)" # rubocop:disable LineLength
          )
      end
    end

    describe "#create_assignment_repo!" do
      it "gets correct github_repository attributes and saves the repo" do
        github_repository = double(id: 1, node_id: 1)
        assignment_repo = double("save!": true)
        expect(service.exercise)
          .to receive_message_chain(:repos, :build)
          .with(
            hash_including(
              github_repo_id: github_repository.id,
              github_global_relay_id: github_repository.node_id,
              "user" => student
            )
          )
          .and_return(assignment_repo)
        service.create_assignment_repo!(github_repository)
      end
      it "raises a Result::Error if record not saved" do
        github_repository = double(id: 1, node_id: 1)
        allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        expect { service.create_assignment_repo!(github_repository) }
          .to raise_error(
            subject::Result::Error,
            "Assignment could not be created, please try again. (Record invalid)"
          )
      end
    end

    describe "#delete_github_repository" do
      it "returns true if github_repo_id is nil" do
        expect(service.delete_github_repository(nil)).to be(true)
      end
      it "returns true if github repository sucessfully deleted" do
        allow_any_instance_of(GitHubOrganization).to receive(:delete_repository).with(anything).and_return(true)
        expect(service.delete_github_repository(1)).to be(true)
      end
      it "returns true if Github::Error is raised" do
        allow_any_instance_of(GitHubOrganization).to receive(:delete_repository).with(anything).and_raise(GitHub::Error)
        expect(service.delete_github_repository(1)).to be(true)
      end
    end

    describe "#push_starter_code!" do
      it "receives a starter code repository for import" do
        assignment_repository = double
        expect(assignment_repository).to receive(:get_starter_code_from).with(instance_of(GitHubRepository))
        service.push_starter_code!(assignment_repository)
      end
      it "raises a GitHub::Error if starter code cannot be imported" do
        assignment_repository = double
        allow(assignment_repository).to receive(:get_starter_code_from).and_raise(GitHub::Error)
        expect { service.push_starter_code!(assignment_repository) }
          .to raise_error(
            subject::Result::Error,
            "We were not able to import you the starter code to your Assignment, please try again. (GitHub::Error)"
          )
      end
    end
    describe "#verify_organization_has_private_repos_available!" do
      before(:each) do
        allow(assignment).to receive(:public?).and_return(false)
      end
      context "organization has private repos" do
        it "returns true" do
          allow_any_instance_of(GitHubOrganization)
            .to receive(:plan)
            .and_return(
              owned_private_repos: 1,
              private_repos: 2
            )
          expect(service.verify_organization_has_private_repos_available!).to eq(true)
        end
      end

      context "organization plan can't be found" do
        before do
          allow_any_instance_of(GitHubOrganization)
            .to receive(:plan)
            .and_raise(GitHub::Error, "Cannot retrieve this organizations repo plan, please reauthenticate your token.")
        end

        it "raises a Result::Error" do
          expect { service.verify_organization_has_private_repos_available! }
            .to raise_error(
              subject::Result::Error,
              "Cannot retrieve this organizations repo plan, please reauthenticate your token."
            )
        end
      end

      context "organization plan limit reached" do
        before do
          expect_any_instance_of(GitHubOrganization)
            .to receive(:plan)
            .and_return(
              owned_private_repos: 1,
              private_repos: 1
            )
        end

        it "raises a Result::Error" do
          expect { service.verify_organization_has_private_repos_available! }
            .to raise_error(subject::Result::Error)
        end
      end
    end
    describe "#add_collaborator_to_github_repository!" do
      it "calls #add_user_to_github_repository!" do
        github_repository = double
        expect(service).to receive(:add_user_to_github_repository!).with(github_repository)
        service.add_collaborator_to_github_repository!(github_repository)
      end
      it "raises GitHub::Error if user addition failed" do
        github_repository = double
        allow(service).to receive(:add_user_to_github_repository!).and_raise(GitHub::Error)
        expect { service.add_collaborator_to_github_repository!(github_repository) }
          .to raise_error(
            subject::Result::Error,
            "We were not able to add the user to the Assignment, please try again. (GitHub::Error)"
          )
      end
    end

    describe "#add_user_to_github_repository!" do
      it "invites user to a github repository" do
        invitation = double(id: 1)
        github_repository = double(full_name: "test/test")
        allow(github_repository)
          .to receive(:invite)
          .and_return(invitation)
        allow(service.exercise).to receive_message_chain("collaborator.github_user.login").with(anything)
        expect(service.exercise)
          .to receive_message_chain("collaborator.github_user.accept_repository_invitation")
          .with(invitation.id)
        service.add_collaborator_to_github_repository!(github_repository)
      end
    end

    describe "#report_error" do
      it "when error is :repository_creation_failed" do
        expect(service.stats_sender).to receive(:report_with_exercise_prefix).with(:repository_creation_failed)
        service.report_error(service.send(:errors, :repository_creation_failed))
      end

      it "when error is :template_repository_creation_failed" do
        expect(service.stats_sender).to receive(:report_with_exercise_prefix).with(:template_repository_creation_failed)
        service.report_error(service.send(:errors, :template_repository_creation_failed))
      end

      it "when error is :collaborator_addition_failed" do
        expect(service.stats_sender).to receive(:report_with_exercise_prefix).with(:collaborator_addition_failed)
        service.report_error(service.send(:errors, :collaborator_addition_failed))
      end

      it "when error is :starter_code_import_failed" do
        expect(service.stats_sender).to receive(:report_with_exercise_prefix).with(:starter_code_import_failed)
        service.report_error(service.send(:errors, :starter_code_import_failed))
      end
    end

    describe "#perform", :vcr do
      describe "successful creation" do
        describe "with importer" do
          let(:assignment) do
            options = {
              title: "Learn Elm",
              organization: organization,
              students_are_repo_admins: true,
              starter_code_repo_id: 1_062_897,
              public_repo: true
            }
            create(:assignment, options)
          end
          it "tracks the how long it too to be created" do
            expect(GitHubClassroom.statsd).to receive(:timing).with("exercise_repo.create.time.with_importer", anything)
            service.perform
          end

          it "tracks create success stat" do
            expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
            expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.import.started")
            service.perform
          end
        end

        describe "with template repos" do
          let(:client) { oauth_client }
          let(:github_organization) { GitHubOrganization.new(client, organization.github_id) }
          let(:github_repository) do
            options = {
              private: false,
              is_template: true,
              auto_init: true,
              accept: "application/vnd.github.baptiste-preview"
            }
            github_organization.create_repository("#{Faker::Company.name} Template", options)
          end
          let(:assignment) do
            options = {
              title: "Learn Elm",
              starter_code_repo_id: github_repository.id,
              organization: organization,
              students_are_repo_admins: true,
              public_repo: true,
              template_repos_enabled: true
            }
            create(:assignment, options)
          end
          let(:service) { subject.new(assignment, student) }
          before(:each) do
            allow(service.exercise).to receive(:use_template_repos?).and_return(true)
          end
          after(:each) do
            client.delete_repository(github_repository.id)
            AssignmentRepo.destroy_all
          end

          it "tracks the how long it too to be created" do
            expect(GitHubClassroom.statsd)
              .to receive(:timing)
              .with("exercise_repo.create.time.with_templates", anything)
            service.perform
          end

          it "tracks create success stat" do
            expect(GitHubClassroom.statsd)
              .to receive(:increment)
              .with("exercise_repo.create.repo.with_templates.started")
            expect(GitHubClassroom.statsd)
              .to receive(:increment)
              .with("exercise_repo.create.repo.with_templates.success")
            expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
            service.perform
          end
        end

        describe "without starter code" do
          let(:assignment) do
            options = {
              title: "Learn Elm",
              organization: organization,
              students_are_repo_admins: true,
              public_repo: true
            }

            create(:assignment, options)
          end
          it "changes invite status if no starter code" do
            allow(service.assignment).to receive(:starter_code?).and_return(false)
            expect(service.invite_status).to receive(:completed!)
            expect(subject::Broadcaster).to receive(:call).with(service.exercise, :create_repo, :text)
            expect(subject::Broadcaster).to receive(:call).with(service.exercise, :repository_creation_complete, :text)
            service.perform
          end
        end

        after(:each) do
          AssignmentRepo.destroy_all
        end

        it "creates an AssignmentRepo as an outside_collaborator" do
          result = service.perform
          expect(result.success?).to be_truthy
          expect(result.repo.assignment).to eql(assignment)
          expect(result.repo.user).to eql(student)
          expect(result.repo.github_global_relay_id).to be_truthy
        end

        it "creates an AssignmentRepo as a member" do
          service = CreateGitHubRepoService.new(assignment, teacher)
          result = service.perform
          expect(result.success?).to be_truthy
          expect(result.repo.assignment).to eql(assignment)
          expect(result.repo.user).to eql(teacher)
          expect(result.repo.github_global_relay_id).to be_truthy
        end

        context "github repository with the same name already exists" do
          before do
            result = service.perform
            assignment_repo = result.repo

            @original_repository = organization.github_client.repository(assignment_repo.github_repo_id)
            assignment_repo.delete
          end

          after do
            organization.github_client.delete_repository(@original_repository.id)
            AssignmentRepo.destroy_all
          end

          it "new repository name has expected suffix" do
            service = CreateGitHubRepoService.new(assignment, student)
            service.perform
            expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
              .with(body: /^.*#{service.exercise.repo_name}.*$/)
          end
        end
      end

      describe "unsuccessful creation" do
        let(:assignment) do
          options = {
            title: "Learn Elm",
            starter_code_repo_id: 1_062_897,
            organization: organization,
            students_are_repo_admins: true,
            public_repo: true
          }

          create(:assignment, options)
        end
        let(:service) { subject.new(assignment, student) }
        it "fails when the repository could not be created" do
          stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
            .to_return(body: "{}", status: 401)

          result = service.perform

          expect(result.failed?).to be_truthy
          expect(result.error).to start_with("GitHub repository could not be created, please try again.")
        end

        context "with a successful repository creation" do
          # Verify that we try to delete the GitHub repository
          # if part of the process fails.
          after(:each) do
            regex = %r{#{github_url("/repositories")}/\d+$}
            expect(WebMock).to have_requested(:delete, regex)
          end

          it "fails when the starter code could not be imported" do
            # https://developer.github.com/v3/migration/source_imports/#start-an-import
            import_regex = %r{#{github_url("/repositories/")}\d+/import$}
            stub_request(:put, import_regex).to_return(body: "{}", status: 401)
            result = service.perform
            expect(result.failed?).to be_truthy
            expect(result.error)
              .to start_with("We were not able to import you the starter code to your Assignment, please try again.")
            expect(WebMock).to have_requested(:put, import_regex)
          end

          it "fails when the user could not be added to the repo" do
            # https://developer.github.com/v3/repos/collaborators/#add-user-as-a-collaborator
            repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
            stub_request(:put, repo_invitation_regex).to_return(body: "{}", status: 401)

            result = service.perform

            expect(result.failed?).to be_truthy
            expect(result.error).to start_with("We were not able to add the user to the Assignment, please try again.")
            expect(WebMock).to have_requested(:put, repo_invitation_regex)
          end

          it "fails when the AssignmentRepo object could not be created" do
            allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

            result = service.perform

            expect(result.failed?).to be_truthy
            expect(result.error).to start_with("Assignment could not be created, please try again.")
          end
        end
      end
    end
  end

  describe "for GroupAssignment", :vcr do
    let(:repo_access)    { RepoAccess.create(user: student, organization: organization) }
    let(:grouping)       { create(:grouping, organization: organization) }
    let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name).id }
    let(:group)          { create(:group, grouping: grouping, github_team_id: github_team_id) }
    let(:group_assignment) do
      create(
        :group_assignment,
        grouping: grouping,
        title: "Learn JavaScript",
        organization: organization,
        public_repo: true,
        starter_code_repo_id: 1_062_897
      )
    end
    let(:service) { subject.new(group_assignment, group) }
    describe "#create_github_repository!" do
      it "creates a new github repo" do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:create_repository)
          .with(service.exercise.repo_name, anything)
        service.create_github_repository!
      end
      it "raises a Result::Error" do
        allow_any_instance_of(GitHubOrganization)
          .to receive(:create_repository)
          .and_raise(GitHub::Error, "Could not created GitHub repository")
        expect { service.create_github_repository! }
          .to raise_error(
            subject::Result::Error,
            "GitHub repository could not be created, please try again. (Could not created GitHub repository)"
          )
      end
    end

    describe "#create_github_repository_from_template!" do
      let(:client) { oauth_client }
      let(:github_organization) { GitHubOrganization.new(client, organization.github_id) }

      let(:github_repository) do
        options = {
          private: false,
          is_template: true,
          auto_init: true,
          accept: "application/vnd.github.baptiste-preview"
        }
        github_organization.create_repository("#{Faker::Company.name} Template", options)
      end

      let(:group_assignment) do
        options = {
          title: "Learn JavaScript",
          starter_code_repo_id: github_repository.id,
          organization: organization,
          students_are_repo_admins: true,
          public_repo: true,
          grouping: grouping,
          template_repos_enabled: true
        }
        create(:group_assignment, options)
      end

      let(:service) { described_class.new(group_assignment, group) }

      after(:each) do
        client.delete_repository(github_repository.id)
        GroupAssignmentRepo.destroy_all
      end

      it "sends a request to GitHubOrganization#create_repository_from_template with correct params" do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:create_repository_from_template)
          .with(
            github_repository.id,
            service.exercise.repo_name,
            hash_including(
              private: false,
              description: "#{service.exercise.repo_name} created by GitHub Classroom"
            )
          )
        service.create_github_repository_from_template!
      end

      it "raises a Result::Error if repository not created" do
        allow_any_instance_of(GitHubOrganization)
          .to receive(:create_repository_from_template)
          .and_raise(GitHub::Error, "Could not created GitHub repository")

        expect { service.create_github_repository_from_template! }
          .to raise_error(
            subject::Result::Error,
            "GitHub repository could not be created from template, please try again. (Could not created GitHub repository)" # rubocop:disable LineLength
          )
      end
    end

    describe "#create_assignment_repo!" do
      it "gets correct github_repository attributes and saves the repo" do
        github_repository = double(id: 1, node_id: 1)
        assignment_repo = double("save!": true)
        expect(service.exercise)
          .to receive_message_chain(:repos, :build)
          .with(
            hash_including(
              github_repo_id: github_repository.id,
              github_global_relay_id: github_repository.node_id,
              "group" => group
            )
          )
          .and_return(assignment_repo)
        service.create_assignment_repo!(github_repository)
      end
      it "raises a Result::Error if record not saved" do
        github_repository = double(id: 1, node_id: 1)
        allow_any_instance_of(GroupAssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        expect { service.create_assignment_repo!(github_repository) }
          .to raise_error(
            subject::Result::Error,
            "Group assignment could not be created, please try again. (Record invalid)"
          )
      end
    end

    describe "#delete_github_repository" do
      it "returns true if github_repo_id is nil" do
        expect(service.delete_github_repository(nil)).to be(true)
      end
      it "returns true if github repository sucessfully deleted" do
        allow_any_instance_of(GitHubOrganization).to receive(:delete_repository).with(anything).and_return(true)
        expect(service.delete_github_repository(1)).to be(true)
      end
      it "returns true if Github::Error is raised" do
        allow_any_instance_of(GitHubOrganization).to receive(:delete_repository).with(anything).and_raise(GitHub::Error)
        expect(service.delete_github_repository(1)).to be(true)
      end
    end

    describe "#push_starter_code!" do
      it "receives a starter code repository for import" do
        assignment_repository = double
        expect(assignment_repository).to receive(:get_starter_code_from).with(instance_of(GitHubRepository))
        service.push_starter_code!(assignment_repository)
      end
      it "raises a GitHub::Error if starter code cannot be imported" do
        assignment_repository = double
        allow(assignment_repository).to receive(:get_starter_code_from).and_raise(GitHub::Error)
        expect { service.push_starter_code!(assignment_repository) }
          .to raise_error(
            subject::Result::Error,
            "We were not able to import you the starter code to your Group assignment, please try again. (GitHub::Error)" # rubocop:disable LineLength
          )
      end
    end
    describe "#verify_organization_has_private_repos_available!" do
      before(:each) do
        allow(group_assignment).to receive(:public?).and_return(false)
      end
      context "organization has private repos" do
        it "returns true" do
          allow_any_instance_of(GitHubOrganization)
            .to receive(:plan)
            .and_return(
              owned_private_repos: 1,
              private_repos: 2
            )
          expect(service.verify_organization_has_private_repos_available!).to eq(true)
        end
      end

      context "organization plan can't be found" do
        before do
          allow_any_instance_of(GitHubOrganization)
            .to receive(:plan)
            .and_raise(GitHub::Error, "Cannot retrieve this organizations repo plan, please reauthenticate your token.")
        end

        it "raises a Result::Error" do
          expect { service.verify_organization_has_private_repos_available! }
            .to raise_error(
              subject::Result::Error,
              "Cannot retrieve this organizations repo plan, please reauthenticate your token."
            )
        end
      end

      context "organization plan limit reached" do
        before do
          expect_any_instance_of(GitHubOrganization)
            .to receive(:plan)
            .and_return(
              owned_private_repos: 1,
              private_repos: 1
            )
        end

        it "raises a Result::Error" do
          expect { service.verify_organization_has_private_repos_available! }
            .to raise_error(subject::Result::Error)
        end
      end
    end
    describe "#add_collaborator_to_github_repository!" do
      it "calls #add_group_to_github_repository!" do
        github_repository = double
        expect(service).to receive(:add_group_to_github_repository!).with(github_repository)
        service.add_collaborator_to_github_repository!(github_repository)
      end
      it "raises GitHub::Error if user addition failed" do
        github_repository = double
        allow(service).to receive(:add_group_to_github_repository!).and_raise(GitHub::Error)
        expect { service.add_collaborator_to_github_repository!(github_repository) }
          .to raise_error(
            subject::Result::Error,
            "We were not able to add the group to the Group assignment, please try again. (GitHub::Error)"
          )
      end
    end

    describe "#add_group_to_github_repository!" do
      it "creates a new github team" do
        github_repository = double(full_name: "test/test")
        expect_any_instance_of(GitHubTeam)
          .to receive(:add_team_repository)
          .with(github_repository.full_name, permission: "push")
        service.add_collaborator_to_github_repository!(github_repository)
      end
    end

    describe "#report_error" do
      it "when error is :repository_creation_failed" do
        expect(service.stats_sender).to receive(:report_with_exercise_prefix).with(:repository_creation_failed)
        service.report_error(service.send(:errors, :repository_creation_failed))
      end

      it "when error is :template_repository_creation_failed" do
        expect(service.stats_sender).to receive(:report_with_exercise_prefix).with(:template_repository_creation_failed)
        service.report_error(service.send(:errors, :template_repository_creation_failed))
      end

      it "when error is :collaborator_addition_failed" do
        expect(service.stats_sender).to receive(:report_with_exercise_prefix).with(:collaborator_addition_failed)
        service.report_error(service.send(:errors, :collaborator_addition_failed))
      end

      it "when error is :starter_code_import_failed" do
        expect(service.stats_sender).to receive(:report_with_exercise_prefix).with(:starter_code_import_failed)
        service.report_error(service.send(:errors, :starter_code_import_failed))
      end
    end

    describe "#perform", :vcr do
      describe "successful creation" do
        after(:each) do
          GroupAssignmentRepo.destroy_all
        end

        it "creates a GroupAssignmentRepo with a group" do
          result = service.perform
          expect(result.success?).to be_truthy
          expect(result.repo.group_assignment).to eql(group_assignment)
          expect(result.repo.group).to eql(group)
          expect(result.repo.github_global_relay_id).to be_truthy
        end

        it "tracks the how long it too to be created" do
          expect(GitHubClassroom.statsd).to receive(:timing)
          service.perform
        end

        it "tracks create success stat" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.import.started")
          expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
          service.perform
        end

        it "changes invite status if no starter code" do
          allow(service.assignment).to receive(:starter_code?).and_return(false)
          expect(service.invite_status).to receive(:completed!)
          expect(subject::Broadcaster).to receive(:call).with(service.exercise, :create_repo, :text)
          expect(subject::Broadcaster).to receive(:call).with(service.exercise, :repository_creation_complete, :text)
          service.perform
        end

        context "github repository with the same name already exists" do
          before do
            result = service.perform
            group_assignment_repo = result.repo

            @original_repository = organization.github_client.repository(group_assignment_repo.github_repo_id)
            group_assignment_repo.delete
          end

          after do
            organization.github_client.delete_repository(@original_repository.id)
            GroupAssignmentRepo.destroy_all
          end

          it "new repository name has expected suffix" do
            service = CreateGitHubRepoService.new(group_assignment, group)
            service.perform
            expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
              .with(body: /^.*#{service.exercise.repo_name}.*$/)
          end
        end
      end

      describe "unsuccessful creation" do
        it "fails when the repository could not be created" do
          stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
            .to_return(body: "{}", status: 401)

          result = service.perform

          expect(result.failed?).to be_truthy
          expect(result.error).to start_with("GitHub repository could not be created, please try again.")
        end

        it "tracks create fail stat" do
          stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
            .to_return(body: "{}", status: 401)

          expect(GitHubClassroom.statsd).to receive(:increment).with("github.error.Unauthorized")
          service.perform
        end

        context "with a successful repository creation" do
          # Verify that we try to delete the GitHub repository
          # if part of the process fails.
          after(:each) do
            regex = %r{#{github_url("/repositories")}/\d+$}
            expect(WebMock).to have_requested(:delete, regex)
          end

          it "fails when the starter code could not be imported" do
            # https://developer.github.com/v3/migration/source_imports/#start-an-import
            import_regex = %r{#{github_url("/repositories/")}\d+/import$}
            stub_request(:put, import_regex).to_return(body: "{}", status: 401)

            result = service.perform
            expect(result.failed?).to be_truthy
            expect(result.error)
              .to start_with("We were not able to import you the starter code to your Group assignment, please try again.") # rubocop:disable LineLength
            expect(WebMock).to have_requested(:put, import_regex)
          end

          it "fails when the team could not be added to the repo" do
            # https://developer.github.com/v3/repos/collaborators/#add-user-as-a-collaborator
            USERNAME_REGEX = GitHub::USERNAME_REGEX
            REPOSITORY_REGEX = GitHub::REPOSITORY_REGEX
            regex = %r{#{github_url("/teams/#{group.github_team_id}/repos/")}#{USERNAME_REGEX}\/#{REPOSITORY_REGEX}$}
            stub_request(:put, regex).to_return(body: "{}", status: 401)

            result = service.perform

            expect(result.failed?).to be_truthy
            expect(result.error)
              .to start_with("We were not able to add the group to the Group assignment, please try again.")
            expect(WebMock).to have_requested(:put, regex)
          end

          it "fails when the GroupAssignmentRepo object could not be created" do
            allow_any_instance_of(GroupAssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

            result = service.perform

            expect(result.failed?).to be_truthy
            expect(result.error).to start_with("Group assignment could not be created, please try again.")
          end
        end
      end
    end
  end
end
