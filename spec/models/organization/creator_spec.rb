# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organization::Creator, type: :model do
  subject                      { described_class.new(github_id: github_organization_id, users: [user]) }
  let(:github_organization_id) { classroom_owner_organization_github_id.to_i }
  let(:user)                   { classroom_teacher }
  let(:organization_webhook) do
    create(
      :organization_webhook,
      github_organization_id: github_organization_id,
      github_id: 1
    )
  end

  describe "::perform", :vcr do
    describe "successful creation" do
      context "no classrooms already exist on the same organization" do
        before do
          expect(subject)
            .to receive(:ensure_organization_webhook_exists!)
            .and_return(organization_webhook)
        end

        it "sends an event to statd" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("classroom.created")

          subject.perform
        end

        context "organization_webhook model with same github_organization_id does not exist" do
          let(:organization) do
            subject.perform.organization
          end

          it "belongs to a new organization webhook" do
            expect(organization.organization_webhook).to be_truthy
          end

          it "has an organization webhook with a github_id" do
            expect(organization.organization_webhook.github_id).to be_truthy
          end

          it "has an organization webhook with a github_organization_id" do
            expect(organization.organization_webhook.github_organization_id).to be_truthy
          end
        end

        context "organization_webhook model with same github_organization_id exists" do
          let(:organization) do
            subject.perform.organization
          end

          before do
            organization_webhook
          end

          it "belongs to the pre existing organization webhook" do
            expect(organization.organization_webhook_id).to eq(organization_webhook.id)
          end

          it "invokes ensure_organization_webhook_exists!" do
            organization
          end
        end
      end

      context "multiple classrooms on same organization" do
        before do
          expect(subject)
            .to receive(:ensure_organization_webhook_exists!)
            .and_return(organization_webhook, organization_webhook)
          result = subject.perform
          @org = result.organization
        end

        it "creates a classroom with the same webhook id as the existing one" do
          result = subject.perform
          expect(result.organization.organization_webhook.github_id).to eql(@org.organization_webhook.github_id)
        end

        it "creates a classroom with the default title but incremented id" do
          result = subject.perform
          expect(result.organization.title).to eql("#{@org.title[0...-2]}-2")
        end
      end
    end

    describe "unsuccessful creation" do
      context "does not allow non admins to be added" do
        subject do
          non_admin_user = create(:user, uid: 1)
          described_class.new(github_id: github_organization_id, users: [non_admin_user])
        end

        it "fails" do
          result = subject.perform
          expect(result.failed?).to be_truthy
        end
      end

      context "deletes the organization if the repository permissions cannot be set to none" do
        before do
          expect(subject)
            .to receive(:ensure_organization_webhook_exists!)
            .and_return(organization_webhook)
        end

        it "fails" do
          stub_request(:patch, github_url("/organizations/#{github_organization_id}"))
            .to_return(body: "{}", status: 401)

          result = subject.perform

          expect(result.failed?).to be_truthy
          expect(Organization.count).to eql(0)
        end
      end

      context "ensure_organization_webhook_exists! fails" do
        context "raises a Result::Error" do
          before do
            expect(subject)
              .to receive(:ensure_organization_webhook_exists!)
              .and_raise(described_class::Result::Error)
          end

          it "fails" do
            expect(subject.perform.failed?).to be_truthy
          end
        end
      end
    end
  end

  describe "#ensure_organization_webhook_exists!", :vcr do
    context "#user_with_admin_org_hook_scope returns nil" do
      before do
        expect(subject)
          .to receive(:user_with_admin_org_hook_scope)
          .and_return(nil)
      end

      it "raises a Result::Error" do
        expect { subject.send(:ensure_organization_webhook_exists!) }
          .to raise_error(described_class::Result::Error, described_class::NO_ADMIN_ORG_TOKEN_ERROR)
      end
    end

    context "#user_with_admin_org_hook_scope returns a user" do
      context "ensure_webhook_is_active! raises a ActiveRecord::RecordInvalid" do
        before do
          expect_any_instance_of(OrganizationWebhook)
            .to receive(:ensure_webhook_is_active!)
            .and_raise(ActiveRecord::RecordInvalid)
        end

        it "raises a Result::Error" do
          expect { subject.send(:ensure_organization_webhook_exists!) }
            .to raise_error(described_class::Result::Error)
        end
      end

      context "ensure_webhook_is_active! raises a GitHub::Error" do
        before do
          expect_any_instance_of(OrganizationWebhook)
            .to receive(:ensure_webhook_is_active!)
            .and_raise(GitHub::Error)
        end

        it "raises a Result::Error" do
          expect { subject.send(:ensure_organization_webhook_exists!) }
            .to raise_error(described_class::Result::Error)
        end
      end

      context "ensure_organization_webhook_exists! returns true" do
        before do
          expect_any_instance_of(OrganizationWebhook)
            .to receive(:ensure_webhook_is_active!)
            .and_return(true)
          organization_webhook
        end

        it "returns the organization_webhook" do
          expect(subject.send(:ensure_organization_webhook_exists!).id).to eq(organization_webhook.id)
        end
      end
    end
  end
end
