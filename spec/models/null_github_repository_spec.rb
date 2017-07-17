# frozen_string_literal: true

require "rails_helper"

RSpec.describe NullGitHubRepository do
  subject { described_class.new }

  describe "#name" do
    it "returns Deleted repository" do
      expect(subject.name).to eql("Deleted repository")
    end
  end

  describe "#full_name" do
    it "returns Deleted repository" do
      expect(subject.full_name).to eql("Deleted repository")
    end
  end

  describe "#html_url" do
    it "returns #" do
      expect(subject.html_url).to eql("#")
    end
  end

  describe "#null?" do
    it "returns true" do
      expect(subject.null?).to be(true)
    end
  end
end
