# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assignment::Creator do
  subject { Assignment::Creator }

  before(:each) do
    GitHubClassroom.flipper[:assignment_creator].disable
  end

  describe "#perform" do
    let(:organization)  { classroom_org }
    let(:user)          { classroom_teacher }
    let(:options) do
      {
        title: "Assignment 1",
        slug: "assignment-1",
        public_repo: true,
        students_are_repo_admins: 0,
        invitations_enabled: 1,
        template_repos_enabled: true,
        creator: user,
        organization: organization
      }
    end

    context "success" do
      it "returns success" do
        result = subject.perform(options: options)
        expect(result.success?).to be true
      end

      it "returns the persisted assignment" do
        result = subject.perform(options: options)
        expect(result.assignment).not_to be_nil
        expect(result.assignment.persisted?).to be true
      end
    end

    context "failure" do
      before(:each) do
        options[:title] = ""
      end

      it "returns failure" do
        result = subject.perform(options: options)
        expect(result.failed?).to be true
        expect(result.error).to eql("Validation failed: Your assignment title must be present")
      end

      it "returns result containing unsaved assignment" do
        result = subject.perform(options: options)
        expect(result.assignment.persisted?).to be false
      end
    end
  end

  context "deadlines" do
    let(:organization)  { classroom_org }
    let(:user)          { classroom_teacher }
    let(:assignment)   { create(:assignment, organization: organization) }

    it "sends an event to statsd" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("exercise.create")
      expect(GitHubClassroom.statsd).to receive(:increment).with("deadline.create")

      deadline = Deadline::Factory.build_from_string(deadline_at: "05/25/2100 13:17-0800")
      subject.perform(options: attributes_for(:assignment, organization: organization)
        .merge(deadline: deadline, organization: organization))
    end

    context "valid datetime for deadline is passed" do
      before do
        deadline = Deadline::Factory.build_from_string(deadline_at: "05/25/2100 13:17-0800")
        subject.perform(options: attributes_for(:assignment, organization: organization)
          .merge(deadline: deadline, organization: organization))
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
        deadline = Deadline::Factory.build_from_string(deadline_at: "I am not a datetime")
        options = attributes_for(:assignment, organization: organization)
          .merge(deadline: deadline, organization: organization)
        subject.perform(options: options)
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
        options = attributes_for(:assignment, organization: organization).merge(organization: organization)
        subject.perform(options: options)
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
