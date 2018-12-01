# frozen_string_literal: true

require "rails_helper"

RSpec.describe NullGitHubOrgHook do
  subject { described_class.new }

  describe "#active" do
    it "returns false" do
      expect(subject.active).to be_falsy
    end
  end

  describe "#active?" do
    it "returns false" do
      expect(subject.active?).to be_falsy
    end
  end

  describe "#name" do
    it "returns nil" do
      expect(subject.name).to be_nil
    end
  end

  describe "#created_at" do
    it "returns nil" do
      expect(subject.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "returns nil" do
      expect(subject.updated_at).to be_nil
    end
  end

  describe "#null?" do
    it "returns true" do
      expect(subject.null?).to be(true)
    end
  end
end
