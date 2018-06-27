# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo::PorterStatusJob, type: :job do
  include ActiveJob::TestHelper

  subject { AssignmentRepo::PorterStatusJob }

  let(:organization)  { classroom_org }
  let(:student)       { classroom_student }
  let(:teacher)       { classroom_teacher }

  let(:assignment) do
    options = {
      title: "Learn Elm",
      starter_code_repo_id: 1_062_897,
      organization: organization,
      students_are_repo_admins: true
    }

    create(:assignment, options)
  end

  before do
    Octokit.reset!
    @client = oauth_client
  end

  before(:each) do
    github_organization = GitHubOrganization.new(@client, organization.github_id)
    @github_repository  = github_organization.create_repository("test-repository", private: true)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  after(:each) do
    @client.delete_repository(@github_repository.id)
  end

  describe "successful repo creation", :vcr do
    it "uses the porter_status queue" do
      subject.perform_later
      expect(subject).to have_been_enqueued.on_queue("porter_status")
    end
  end
end
