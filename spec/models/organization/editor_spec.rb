# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organization::Editor do
  subject { Organization::Editor }

  let(:organization) { classroom_org }

  describe "#perform" do
    describe "attribute updating" do
      it "can update regular attributes" do
        subject.perform(organization: organization, options: { title: "New Classroom Title" })
        expect(organization.title).to eq("New Classroom Title")
      end

      context "updating archive setting" do
        context "archiving a classroom" do
          before do
            assignment = create(
              :assignment,
              title: "Assignment 1",
              organization: organization,
              invitations_enabled: true
            )
            group_assignment = create(
              :group_assignment,
              title: "Group Assignment 1",
              organization: organization,
              invitations_enabled: true
            )
            organization.assignments << assignment
            organization.group_assignments << group_assignment
          end

          it "changes the archived_at column in the organization" do
            subject.perform(organization: organization, options: { archived: "true" })
            expect(organization.archived_at).to be_an_instance_of(ActiveSupport::TimeWithZone)
          end

          it "disables assignment invitations for all assignments" do
            subject.perform(organization: organization, options: { archived: "true" })
            expect(organization.assignments).to all(have_attributes(invitations_enabled: false))
            expect(organization.group_assignments).to all(have_attributes(invitations_enabled: false))
          end
        end

        it "can unarchive a classroom" do
          subject.perform(organization: organization, options: { archived: "false" })
          expect(organization.archived_at).to be_nil
        end
      end
    end
  end
end
