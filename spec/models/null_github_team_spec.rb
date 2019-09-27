# frozen_string_literal: true

require "rails_helper"

RSpec.describe NullGitHubTeam do
  subject { described_class.new }

  describe "#name" do
    it "returns Deleted team" do
      expect(subject.name).to eql("Deleted team")
    end
  end

  describe "#null?" do
    it "returns true" do
      expect(subject.null?).to be(true)
    end
  end

  describe "#organization" do
    it "returns a NullGitHubOrganization" do
      expect(subject.organization.class).to eql(NullGitHubOrganization)
    end
  end

  describe "#slug" do
    it "returns ghost" do
      expect(subject.slug).to eql("ghost")
    end
  end
end
