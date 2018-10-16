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

  describe "#github_client",:vcr do
    context "random token disabled" do
      it "returns first user token" do
        client = subject.github_client(random_token: false)
        expect(client.access_token).to eql(subject.users.first.token)
      end
    end

    # TODO: Add randomness check for token
    context "random token enabled" do
      before do
        @users = subject.users
        subject.users.delete_all
        subject.users << classroom_teacher
      end

      after do
        subject.users = @users
      end

      context "no valid tokens" do
        before do
          allow_any_instance_of(GitHubOrganization).to receive(:admin?)
            .and_return(false)
        end

        it "raises error" do
          expect { subject.github_client(random_token: true) }.to raise_error(Organization::NoValidTokensError)
        end
      end

      context "classroom has one valid token and one invalid token" do
        before do
          subject.users << classroom_student
          allow_any_instance_of(GitHubOrganization).to receive(:admin?)
            .with(classroom_teacher.github_user.login)
            .and_return(true)

          allow_any_instance_of(GitHubOrganization).to receive(:admin?)
            .with(classroom_student.github_user.login)
            .and_return(false)
        end

        it "returns the valid token" do
          client = subject.github_client(random_token: true)
          expect(client.access_token).to eql(classroom_teacher.token)
        end
      end
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
