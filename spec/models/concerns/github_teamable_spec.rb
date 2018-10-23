# frozen_string_literal: true

require "rails_helper"

class MockGitHubTeam
  attr_reader :id

  def initialize(_, id)
    @id
  end
end

shared_examples_for "github_teamable" do
  let(:model) { create(described_class.to_s.underscore, organization: classroom_org) }

  describe "#create_github_team", :vcr do
    before do
      expect_any_instance_of(GitHubOrganization)
        .to receive(:create_team)
        .with(model.title)
        .and_return(MockGitHubTeam.new(nil, rand(1..1_000_000)))
    end

    it "updates the github_team_id" do
      model.create_github_team
      expect(model.github_team_id_changed?).to be_truthy
    end
  end

  describe "#destroy_github_team", :vcr do
    it "returns true" do
      model.github_team_id = nil
      expect(model.destroy_github_team).to be_truthy
    end

    context "has a github_team_id" do
      before do
       expect_any_instance_of(GitHubOrganization)
        .to receive(:delete_team)
        .and_return(nil)
      end

      it "updates the github_team_id" do
        model.destroy_github_team
        expect(model.github_team_id_changed?).to be_truthy
      end

      it "returns true on success" do
        expect(model.destroy_github_team).to be_truthy
      end
    end
  end
end
