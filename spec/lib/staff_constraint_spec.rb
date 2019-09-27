# frozen_string_literal: true

require "rails_helper"

describe StaffConstraint do
  subject { described_class.new }

  describe "#matches?" do
    context "when without user session" do
      let(:request) { double("request", session: {}) }

      it "returns false" do
        expect(subject.matches?(request)).to be_falsey
      end
    end

    context "when with user session" do
      let(:id) { double("id") }
      let(:request) { double("request", session: { user_id: id }) }

      before do
        allow(User).to receive(:find).with(id).and_return(user)
      end

      context "and user is a staff member" do
        let(:user) { double("user", staff?: true) }

        it "returns true" do
          expect(subject.matches?(request)).to be_truthy
        end
      end

      context "and user is not a staff member" do
        let(:user) { double("user", staff?: false) }

        it "returns false" do
          expect(subject.matches?(request)).to be_falsey
        end
      end
    end
  end
end
