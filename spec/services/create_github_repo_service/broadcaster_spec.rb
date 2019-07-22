# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService::Broadcaster do
  let(:exercise) do
    double(
      "user?": true,
      humanize: "user",
      assignment_type: "assignment",
      collaborator: double(id: 1),
      assignment: double(id: 1),
      status: "completed"
    )
  end

  describe ".call" do
    it "sends a broadcast message" do
      expect(ActionCable.server).to receive(:broadcast)
      described_class.call(exercise, :repository_creation_complete, :text)
    end
  end

  describe ".build_message" do
    context "selects the correct message" do
      it "if message is :repository_creation_complete" do
        message = described_class.build_message(exercise, :repository_creation_complete, :text)
        expect(message[:text]).to eq("Your GitHub repository was created.")
      end

      it "if message is :import_ongoing" do
        message = described_class.build_message(exercise, :import_ongoing, :text)
        expect(message[:text]).to eq("Your GitHub repository is importing starter code.")
      end

      it "if message is :create_repo" do
        message = described_class.build_message(exercise, :create_repo, :text)
        expect(message[:text]).to eq("Creating GitHub repository.")
      end

      it "if message is :importing_starter_code" do
        message = described_class.build_message(exercise, :importing_starter_code, :text)
        expect(message[:text]).to eq("Importing starter code.")
      end
    end

    it "sets repo url if present" do
      message = described_class.build_message(exercise, :create_repo, :text, "http://example.com")
      expect(message[:repo_url]).to eq("http://example.com")
    end

    it "sets the correct status" do
      message = described_class.build_message(exercise, :repository_creation_complete, :text, "http://example.com")
      expect(message[:status]).to eq("completed")
    end
  end

  describe "for individual exercise" do
    describe ".build_channel" do
      it "calls the RepositoryCreationStatusChannel" do
        expect(RepositoryCreationStatusChannel).to receive(:channel)
        described_class.build_channel(exercise)
      end

      it "builds the correct channel" do
        expect(described_class.build_channel(exercise)).to eq("repository_creation_status_1_1")
      end
    end

    describe ".channel_hash" do
      it "builds a hash with :user_id and :assignment_id as keys" do
        hash = described_class.channel_hash(exercise)
        expect(hash).to eq(user_id: exercise.collaborator.id, assignment_id: exercise.assignment.id)
      end
    end
  end

  describe "for group exercise" do
    let(:exercise) do
      double(
        "user?": false,
        humanize: "group",
        assignment_type: "group_assignment",
        collaborator: double(id: 1),
        assignment: double(id: 1),
        status: "completed"
      )
    end

    describe ".build_channel" do
      it "calls the GroupRepositoryCreationStatusChannel" do
        expect(GroupRepositoryCreationStatusChannel).to receive(:channel)
        described_class.build_channel(exercise)
      end

      it "builds the correct channel" do
        expect(described_class.build_channel(exercise)).to eq("group_repository_creation_status_1_1")
      end
    end

    describe ".channel_hash" do
      it "builds a hash with :group_id and :group_assignment_id as keys" do
        hash = described_class.channel_hash(exercise)
        expect(hash).to eq(group_id: exercise.collaborator.id, group_assignment_id: exercise.assignment.id)
      end
    end
  end
end
