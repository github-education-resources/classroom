# frozen_string_literal: true

require "rails_helper"

RSpec.describe NullGitHubOrganization do
  subject { described_class.new }

  describe "#avatar_url" do
    it "returns the avatar url for ghost user" do
      expect(subject.avatar_url).to eql("https://avatars.githubusercontent.com/u/10137?v=3")
    end
  end

  describe "#html_url" do
    it "returns the html_url for ghost user" do
      expect(subject.html_url).to eql("https://github.com/ghost")
    end
  end

  describe "#login" do
    it "returns ghost" do
      expect(subject.login).to eql("ghost")
    end
  end

  describe "#name" do
    it "returns Deleted organization" do
      expect(subject.name).to eql("Deleted organization")
    end
  end

  describe "#null?" do
    it "returns true" do
      expect(subject.null?).to be(true)
    end
  end
end
