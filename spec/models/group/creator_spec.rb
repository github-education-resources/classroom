# frozen_string_literal: true

require "rails_helper"

RSpec.describe Group::Creator, type: :model do
  let(:title)         { Faker::Team.name[0..39] }
  let(:grouping)      { create(:grouping) }
  let(:group)         { create(:group, title: title, grouping: grouping) }

  describe "class#perform" do
    subject { described_class.perform(title: title, grouping: grouping) }

    it "calls intsance method #perform" do
      expect_any_instance_of(described_class)
        .to receive(:perform)
      subject
    end
  end

  describe "#perform" do
    subject { described_class.new(title: title, grouping: grouping).perform }

    before do
      expect(Group)
        .to receive(:new)
        .with(title: title, grouping: grouping)
        .and_return(group)
    end

    context "when create_github_team is successful" do
      before do
        expect(group)
          .to receive(:create_github_team)
          .and_return(true)
      end

      it "returns success" do
        expect(subject.success?).to be_truthy
      end

      it "has a group" do
        expect(subject.group).to eq(group)
      end

      context "when the record is invalid" do
        before do
          expect(group)
            .to receive(:save!)
            .and_raise(ActiveRecord::RecordInvalid)
          expect(group)
            .to receive(:silently_destroy_github_team)
        end

        it "returns failed" do
          expect(subject.failed?).to be_truthy
        end

        it "has an error" do
          expect(subject.error).to be_truthy
        end
      end
    end

    context "when creating a github team fails" do
      before do
        expect(group)
          .to receive(:create_github_team)
          .and_raise(GitHub::Error)
        expect(group)
          .to receive(:silently_destroy_github_team)
      end

      it "returns failed" do
        expect(subject.failed?).to be_truthy
      end

      it "has an error" do
        expect(subject.error).to be_truthy
      end
    end
  end
end
