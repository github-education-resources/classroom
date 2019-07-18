# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService::StatsSender do
  describe "#report_default" do
    context "reports a valid stat" do
      it "when message is :success" do
        entity = double
        stats_sender = described_class.new(entity)
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
        stats_sender.report_default(:success)
      end
      it "when message is :failure" do
        entity = double
        stats_sender = described_class.new(entity)
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
        stats_sender.report_default(:failure)
      end
    end
    it "raises a StatsSender::InvalidStatError when stat not found" do
      entity = double
      stats_sender = described_class.new(entity)
      expect { stats_sender.report_default(:foo) }.to raise_error(described_class::InvalidStatError)
    end
  end
  describe "#report_with_exercise_prefix" do
    context "for group assignment" do
      let(:entity) { double(stat_prefix: "group_exercise_repo") }
      let(:stats_sender) { described_class.new(entity) }
      it "when message is :repository_creation_failed" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.repo.fail")
        stats_sender.report_with_exercise_prefix(:repository_creation_failed)
      end
      it "when message is :collaborator_addition_failed" do
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
                .with("group_exercise_repo.create.adding_collaborator.fail")
        stats_sender.report_with_exercise_prefix(:collaborator_addition_failed)
      end
      it "when message is :starter_code_import_failed" do
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
                .with("group_exercise_repo.create.importing_starter_code.fail")
        stats_sender.report_with_exercise_prefix(:starter_code_import_failed)
      end
      it "when message is :import_started" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.import.started")
        stats_sender.report_with_exercise_prefix(:import_started)
      end
      context "for assignment" do
        let(:entity) { double(stat_prefix: "exercise_repo") }
        let(:stats_sender) { described_class.new(entity) }
        it "when message is :repository_creation_failed" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.repo.fail")
          stats_sender.report_with_exercise_prefix(:repository_creation_failed)
        end
        it "when message is :collaborator_addition_failed" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.adding_collaborator.fail")
          stats_sender.report_with_exercise_prefix(:collaborator_addition_failed)
        end
        it "when message is :starter_code_import_failed" do
          expect(GitHubClassroom.statsd)
            .to receive(:increment)
                  .with("exercise_repo.create.importing_starter_code.fail")
          stats_sender.report_with_exercise_prefix(:starter_code_import_failed)
        end
        it "when message is :import_started" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.import.started")
          stats_sender.report_with_exercise_prefix(:import_started)
        end
      end
    end
    it "raises a StatsSender::InvalidStatError when stat not found" do
      entity = double
      stats_sender = described_class.new(entity)
      expect { stats_sender.report_with_exercise_prefix(:foo) }.to raise_error(described_class::InvalidStatError)
    end
  end
  describe "#timing" do
    context "for group assignment" do
      let(:entity) { double(stat_prefix: "group_exercise_repo") }
      let(:stats_sender) { described_class.new(entity) }
      it "reports time" do
        expect(GitHubClassroom.statsd).to receive(:timing).with("group_exercise_repo.create.time", instance_of(Float))
        stats_sender.timing(Time.zone.now)
      end
    end
    context "for assignment" do
      let(:entity) { double(stat_prefix: "exercise_repo") }
      let(:stats_sender) { described_class.new(entity) }
      it "reports time" do
        expect(GitHubClassroom.statsd).to receive(:timing).with("exercise_repo.create.time", instance_of(Float))
        stats_sender.timing(Time.zone.now)
      end
    end
  end
end
