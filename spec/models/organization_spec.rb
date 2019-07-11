# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organization, type: :model do
  subject { create(:organization, github_id: 12_345) }

  it { should belong_to(:organization_webhook) }
  it { should belong_to(:roster).optional }
  it { should have_one(:lti_configuration) }

  describe ".search" do
    before do
      expect(subject).to_not be_nil
    end

    it "searches by id" do
      results = Organization.search(subject.id)
      expect(results.to_a).to include(subject)
    end

    it "searches by github_id" do
      byebug
      results = Organization.search(subject.github_id)
      expect(results.to_a).to include(subject)
    end

    it "searches by title" do
      results = Organization.search(subject.title)
      expect(results.to_a).to include(subject)
    end

    it "searches by slug" do
      results = Organization.search(subject.slug)
      expect(results.to_a).to include(subject)
    end

    it "does not return the org when it shouldn't" do
      results = Organization.search("spaghetto")
      expect(results.to_a).to_not include(subject)
    end
  end

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

  describe "#last_classroom_on_org?" do
    context "only one classroom with github_id" do
      it "returns true" do
        expect(subject.last_classroom_on_org?).to be_truthy
      end
    end

    context "multiple classrooms with same github_id" do
      before do
        create(:organization, github_id: 12_345)
      end

      it "returns false" do
        expect(subject.last_classroom_on_org?).to be_falsey
      end
    end

    context "multiple classrooms with different github_ids" do
      before do
        create(:organization, github_id: 0)
      end

      it "returns true" do
        expect(subject.last_classroom_on_org?).to be_truthy
      end
    end
  end

  describe "callbacks" do
    describe "before_destroy" do
      describe "#silently_remove_organization_webhook", :vcr do
        context "multiple classrooms on organization" do
          before do
            create(:organization, github_id: 12_345)
          end

          it "does not delete the webhook from GitHub" do
            subject.organization_webhook.update(github_id: 9_999_999)

            org_id     = subject.github_id
            webhook_id = subject.organization_webhook.github_id

            subject.destroy

            expect(WebMock).to_not have_requested(:delete, github_url("/organizations/#{org_id}/hooks/#{webhook_id}"))
          end
        end

        context "last classroom on organization" do
          it "deletes the webhook from GitHub" do
            subject.organization_webhook.update(github_id: 9_999_999)

            webhook_id = subject.organization_webhook.github_id

            subject.destroy

            expect(WebMock).to have_requested(:delete, github_url("/orgs/ghost/hooks/#{webhook_id}"))
          end
        end
      end
    end
  end
end
