# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvitationHelper, type: :helper do
  subject { described_class }

  let(:assignment_invitation) { create(:assignment_invitation) }

  describe "#attributes" do
    context "short key is present" do
      it "returns a hash of attributes" do
        attributes = {
          type:     "assignment_invitation",
          key:       assignment_invitation.short_key,
          url:       "http://github.dev/a/#{assignment_invitation.short_key}"
        }

        expect(subject.attributes(assignment_invitation, "http://github.dev")). to eql(attributes)
      end
    end

    context "short key is not present" do
      before(:each) do
        assignment_invitation.update_attributes(short_key: nil)
      end

      it "returns a hash of attributes" do
        attributes = {
          type:     "assignment_invitation",
          key:       assignment_invitation.key,
          url:       "http://github.dev/assignment-invitations/#{assignment_invitation.key}"
        }

        expect(subject.attributes(assignment_invitation, "http://github.dev")). to eql(attributes)
      end
    end
  end
end
