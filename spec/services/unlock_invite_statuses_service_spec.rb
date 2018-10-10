# frozen_string_literal: true

require "rails_helper"

describe UnlockInviteStatusesService do
  describe "#each_invite_status" do
    before do
      @invite_statuses = InviteStatus.statuses.keys.map { |status| create(:invite_status, status: status) }
    end

    it "yeilds with each invite_status only if the status is locked?" do
      fetched_invite_statuses = []
      described_class.send(:each_invite_status) do |_, invite_status|
        fetched_invite_statuses << invite_status
      end
      expect(fetched_invite_statuses).to eq(@invite_statuses.select(&:locked?))
    end

    it "yeilds with each invite_statuses assocated class" do
      described_class.send(:each_invite_status) do |model, invite_status|
        expect(invite_status.class).to eq(model)
      end
    end
  end

  describe "#create_stat_map" do
    let(:stat_map) { described_class.send(:create_stat_map) }

    UnlockInviteStatusesService::INVITE_STATUS_MODELS.each do |model|
      it "has the field '#{model.to_s.underscore}'" do
        expect(stat_map[model.to_s.underscore]).to be_truthy
      end

      it "has the field 'total_#{model.to_s.underscore.pluralize}'" do
        expect(stat_map["total_#{model.to_s.underscore.pluralize}"]).to be_truthy
      end

      SetupStatus::LOCKED_STATUSES.each do |status|
        it "has the field '#{status}' in '#{model.to_s.underscore}'" do
          expect(stat_map[model.to_s.underscore][status]).to be_truthy
        end
      end
    end
  end

  describe "#unlock_invite_statuses" do
    before(:all) do
      described_class::TIME = 0.hours
    end

    before do
      @invite_statuses = InviteStatus.statuses.keys.map { |status| create(:invite_status, status: status) }
    end

    it "unlocks all locked? invite_statuses" do
      locked_invite_statuses = @invite_statuses.select(&:locked?)
      described_class.unlock_invite_statuses
      locked_invite_statuses.map(&:reload).each do |invite_status|
        expect(invite_status.unaccepted?).to be_truthy
      end
    end

    it "checks change_to_success_if_complete on every invite status" do
      locked_invite_statuses = @invite_statuses.select(&:locked?)
      number_of_times = locked_invite_statuses.map(&:reload).count
      expect(described_class).to receive(:change_to_success_if_complete).exactly(number_of_times).times
      described_class.unlock_invite_statuses
    end

    it "returns a stat map with totals of all the locked statuses that were unlocked" do
      stat_map = described_class.unlock_invite_statuses
      expect(stat_map)
        .to eq(
          "invite_status" => {
            "waiting" => 1,
            "creating_repo" => 1,
            "importing_starter_code" => 1
          },
          "total_invite_statuses" => 3,
          "group_invite_status" => {
            "waiting" => 0,
            "creating_repo" => 0,
            "importing_starter_code" => 0
          },
          "total_group_invite_statuses" => 0
        )
    end

    it "invokes #report_to_failbot for each unlocked invite_status" do
      locked_invite_statuses = @invite_statuses.select(&:locked?)
      locked_invite_statuses.map(&:reload).each do
        expect(described_class)
          .to receive(:report_to_failbot)
      end
      described_class.unlock_invite_statuses
    end
  end

  describe "#report_to_failbot" do
    let(:invite_status) { create(:invite_status) }
    it "reports a detailed error with context to failbot" do
      expect(Failbot)
        .to receive(:report!)
      described_class.send(
        :report_to_failbot,
        InviteStatus.to_s.underscore,
        "unaccepted",
        invite_status.updated_at,
        invite_status
      )
    end
  end

  describe "#change_to_success_if_complete" do
    it "calls complete_if_assignment_repo_is_ready if InviteStatus is passed" do
      expect(described_class)
        .to receive(:complete_if_assignment_repo_is_ready)
      described_class.send(:change_to_success_if_complete, InviteStatus, nil)
    end

    it "calls complete_if_group_assignment_repo_is_ready if GroupInviteStatus is passed" do
      expect(described_class)
        .to receive(:complete_if_group_assignment_repo_is_ready)
      described_class.send(:change_to_success_if_complete, GroupInviteStatus, nil)
    end
  end

  describe "#complete_if_assignment_repo_is_ready", :vcr do
    let(:organization) { classroom_org     }
    let(:user)         { classroom_student }

    context "assignment_repo doesnt exist" do
      let(:invite_status) { create(:invite_status) }

      it "returns false if no assignment_repo exists" do
        expect(described_class.send(:complete_if_assignment_repo_is_ready, invite_status)).to eq(false)
      end
    end

    context "assignment doesnt have started code" do
      let(:invitation)    { create(:assignment_invitation, organization: organization) }
      let(:invite_status) { create(:invite_status, user: user, assignment_invitation: invitation) }
      let(:assignment_repo) do
        create(:assignment_repo, user: user, assignment: invitation.assignment, github_repo_id: 8485)
      end

      before do
        assignment_repo
      end

      it "returns true if the assignment repo exists" do
        expect(described_class.send(:complete_if_assignment_repo_is_ready, invite_status)).to eq(true)
      end

      it "makes the invite_status completed if the assignment repo exists" do
        described_class.send(:complete_if_assignment_repo_is_ready, invite_status)
        expect(invite_status.reload.completed?).to eq(true)
      end
    end

    context "assignment has started code" do
      let(:assignment) do
        create(:assignment, starter_code_repo_id: 1_062_897, organization: organization)
      end
      let(:invitation)    { create(:assignment_invitation, assignment: assignment) }
      let(:invite_status) { create(:invite_status, user: user, assignment_invitation: invitation) }
      let(:assignment_repo) do
        create(:assignment_repo, user: user, assignment: assignment, github_repo_id: 8485)
      end

      context "import finished" do
        before do
          expect_any_instance_of(GitHubRepository).to receive(:imported?).and_return(true)
          assignment_repo
        end

        it "returns true" do
          expect(described_class.send(:complete_if_assignment_repo_is_ready, invite_status)).to eq(true)
        end

        it "makes the invite_status completed" do
          described_class.send(:complete_if_assignment_repo_is_ready, invite_status)
          expect(invite_status.reload.completed?).to eq(true)
        end
      end

      context "import isn't finished" do
        before do
          expect_any_instance_of(GitHubRepository).to receive(:imported?).and_return(true)
          assignment_repo
        end

        it "returns false" do
          expect(described_class.send(:complete_if_assignment_repo_is_ready, invite_status)).to eq(true)
        end
      end
    end
  end

  describe "#complete_if_group_assignment_repo_is_ready", :vcr do
    let(:organization)  { classroom_org     }
    let(:user)          { classroom_student }

    context "group_assignment_repo doesnt exist" do
      let(:group_assignment) { create(:group_assignment, organization: organization) }
      let(:grouping)   { group_assignment.grouping }
      let(:group_name) { "#{Faker::Company.name} Team" }
      let(:group) do
        group = Group.create(grouping: grouping, title: group_name)
        group.repo_accesses << RepoAccess.create(user: user, organization: organization)
        group
      end
      let(:invitation)    { create(:group_assignment_invitation, group_assignment: group_assignment) }
      let(:invite_status) { invitation.status(group) }

      it "returns false if no group_assignment_repo exists" do
        expect(described_class.send(:complete_if_group_assignment_repo_is_ready, invite_status)).to eq(false)
      end
    end

    context "assignment doesnt have started code" do
      let(:group_assignment) do
        create(
          :group_assignment,
          organization: organization,
          title: "HTML5"
        )
      end
      let(:grouping)   { group_assignment.grouping }
      let(:group_name) { "#{Faker::Company.name} Team" }
      let(:group) do
        group = Group.create(grouping: grouping, title: group_name)
        group.repo_accesses << RepoAccess.create(user: user, organization: organization)
        group
      end
      let(:invitation)    { create(:group_assignment_invitation, group_assignment: group_assignment) }
      let(:invite_status) { invitation.status(group) }

      before do
        GroupAssignmentRepo.create!(group_assignment: group_assignment, group: group)
      end

      it "returns true if the assignment repo exists" do
        expect(described_class.send(:complete_if_group_assignment_repo_is_ready, invite_status)).to eq(true)
      end

      it "makes the invite_status completed if the assignment repo exists" do
        described_class.send(:complete_if_group_assignment_repo_is_ready, invite_status)
        expect(invite_status.reload.completed?).to eq(true)
      end
    end

    context "assignment has started code" do
      let(:group_assignment) do
        create(
          :group_assignment,
          starter_code_repo_id: 1_062_897,
          organization: organization,
          title: "HTML5"
        )
      end
      let(:grouping)   { group_assignment.grouping }
      let(:group_name) { "#{Faker::Company.name} Team" }
      let(:group) do
        group = Group.create(grouping: grouping, title: group_name)
        group.repo_accesses << RepoAccess.create(user: user, organization: organization)
        group
      end
      let(:invitation)    { create(:group_assignment_invitation, group_assignment: group_assignment) }
      let(:invite_status) { invitation.status(group) }

      context "import finished" do
        before do
          expect_any_instance_of(GitHubRepository).to receive(:imported?).and_return(true)
          GroupAssignmentRepo.create!(group_assignment: group_assignment, group: group)
        end

        it "returns true" do
          expect(described_class.send(:complete_if_group_assignment_repo_is_ready, invite_status)).to eq(true)
        end

        it "makes the invite_status completed" do
          described_class.send(:complete_if_group_assignment_repo_is_ready, invite_status)
          expect(invite_status.reload.completed?).to eq(true)
        end
      end

      context "import isn't finished" do
        before do
          expect_any_instance_of(GitHubRepository).to receive(:imported?).and_return(true)
          GroupAssignmentRepo.create!(group_assignment: group_assignment, group: group)
        end

        it "returns false" do
          expect(described_class.send(:complete_if_group_assignment_repo_is_ready, invite_status)).to eq(true)
        end
      end
    end
  end
end
