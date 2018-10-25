# frozen_string_literal: true

require "rails_helper"

RSpec.describe Group::Creator, type: :model do
  let(:title)    { Faker::Team.name[0..39] }
  let(:grouping) { create(:grouping) }
  let(:group)    { create(:group, title: title, grouping: grouping, github_team_id: 2_977_000) }

  describe "class#perform" do
    subject { described_class.perform(title: title, grouping: grouping) }

    it "calls intsance method #perform" do
      expect_any_instance_of(described_class)
        .to receive(:perform)
      subject
    end
  end

  describe "#perform", :vcr do
    subject { described_class.new(title: title, grouping: grouping).perform }

    it "creates a group" do
      expect(Group)
        .to receive(:new)
        .and_return(group)
      subject
    end
  end
end
