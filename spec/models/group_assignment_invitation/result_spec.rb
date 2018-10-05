# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentInvitation::Result, type: :model do
  subject                     { described_class }
  let(:group_assignment_repo) { GroupAssignmentRepo.new }
  let(:error)                 { "Something went wrong" }

  describe "success" do
    before do
      @result = subject.success(group_assignment_repo)
    end

    it "has an group_assignment_repo" do
      expect(@result.group_assignment_repo).to be_truthy
    end

    it "has a status of :success" do
      expect(@result.status).to eq(:success)
    end

    it "is success?" do
      expect(@result.success?).to be_truthy
    end

    it "does not have an error" do
      expect(@result.error).to be_nil
    end
  end

  describe "failed" do
    before do
      @result = subject.failed(error)
    end

    it "doesn't have an group_assignment_repo" do
      expect(@result.group_assignment_repo).to be_nil
    end

    it "has a status of :failed" do
      expect(@result.status).to eq(:failed)
    end

    it "is failed?" do
      expect(@result.failed?).to be_truthy
    end

    it "has an error" do
      expect(@result.error).to eq(error)
    end
  end

  describe "pending" do
    before do
      @result = subject.pending
    end

    it "doesn't have an group_assignment_repo" do
      expect(@result.group_assignment_repo).to be_nil
    end

    it "has a status of :pending" do
      expect(@result.status).to eq(:pending)
    end

    it "is pending?" do
      expect(@result.pending?).to be_truthy
    end

    it "does not have an error" do
      expect(@result.error).to be_nil
    end
  end
end
