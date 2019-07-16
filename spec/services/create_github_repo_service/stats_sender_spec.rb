# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService::StatsSender do
  describe "#report" do
    context "reports a valid stat" do
      it "when #success is called" do
        entity = double
        stats_sender = described_class.new(entity)
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
        stats_sender.report(:success)
      end
      it "when #failure is called" do
        entity = double
        stats_sender = described_class.new(entity)
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
        stats_sender.report(:failure)
      end
      context "for group assignment" do
        let(:entity) { double(stat_prefix: "group_exercise_repo") }
        let(:stats_sender) { described_class.new(entity) }
        it "when #repository_creation_failed is called" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.repo.fail")
          stats_sender.report(:repository_creation_failed)
        end
        it "when #collaborator_addition_failed is called" do
          expect(GitHubClassroom.statsd)
            .to receive(:increment)
            .with("group_exercise_repo.create.adding_collaborator.fail")
          stats_sender.report(:collaborator_addition_failed)
        end
        it "when #starter_code_import_failed is called" do
          expect(GitHubClassroom.statsd)
            .to receive(:increment)
            .with("group_exercise_repo.create.importing_starter_code.fail")
          stats_sender.report(:starter_code_import_failed)
        end
        it "when #import_started is called" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.import.started")
          stats_sender.report(:import_started)
        end
        context "for assignment" do
          let(:entity) { double(stat_prefix: "exercise_repo") }
          let(:stats_sender) { described_class.new(entity) }
          it "when #repository_creation_failed is called" do
            expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.repo.fail")
            stats_sender.report(:repository_creation_failed)
          end
          it "when #collaborator_addition_failed is called" do
            expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.adding_collaborator.fail")
            stats_sender.report(:collaborator_addition_failed)
          end
          it "when #starter_code_import_failed is called" do
            expect(GitHubClassroom.statsd)
              .to receive(:increment)
              .with("exercise_repo.create.importing_starter_code.fail")
            stats_sender.report(:starter_code_import_failed)
          end
          it "when #import_started is called" do
            expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.import.started")
            stats_sender.report(:import_started)
          end
        end
      end
    end
    it "raises a StatsSender::InvalidStatError when stat not found" do
      entity = double
      stats_sender = described_class.new(entity)
      expect { stats_sender.report(:foo) }.to raise_error(described_class::InvalidStatError)
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
