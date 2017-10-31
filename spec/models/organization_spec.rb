# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organization, type: :model do
  subject { create(:organization, github_id: 12_345) }

  describe "roster association" do
    it "can have a roster" do
      subject.roster = create(:roster)
      expect(subject.save).to be_truthy
    end

    it "can have no roster" do
      subject.roster = nil

      expect(subject.save).to be_truthy
    end
  end

  describe "when title is changed" do
    it "updates the slug" do
      subject.update_attributes(title: "New Title")
      expect(subject.slug).to eql("#{subject.github_id}-new-title")
    end
  end

  describe "#all_assignments" do
    context "new Organization" do
      it "returns an empty array" do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(0)
      end
    end

    context "with Assignments and GroupAssignments" do
      before do
        create(:assignment, organization: subject)
        create(:group_assignment, organization: subject)
      end

      it "should return an array of Assignments and GroupAssignments" do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(2)
      end
    end
  end

  describe "#flipper_id" do
    it "should return an id" do
      expect(subject.flipper_id).to eq("Organization:#{subject.id}")
    end
  end

  describe "#github_client" do
    it "selects a users github_client at random" do
      expect(subject.github_client.class).to eql(Octokit::Client)
    end
  end

  describe "callbacks" do
    describe "before_destroy" do
      describe "#silently_remove_organization_webhook", :vcr do
        it "deletes the webhook from GitHub" do
          subject.update_attributes(webhook_id: 9_999_999, is_webhook_active: true)

          org_id     = subject.github_id
          webhook_id = subject.webhook_id

          subject.destroy

          expect(WebMock).to have_requested(:delete, github_url("/organizations/#{org_id}/hooks/#{webhook_id}"))
        end
      end
    end
  end
end
