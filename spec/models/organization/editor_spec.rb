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
        it "can archive a classroom" do
          subject.perform(organization: organization, options: { archived: "true" })
          expect(organization.archived_at).to be_an_instance_of(ActiveSupport::TimeWithZone)
        end

        it "can unarchive a classroom" do
          subject.perform(organization: organization, options: { archived: "false" })
          expect(organization.archived_at).to be_nil
        end
      end
    end
  end
end
