# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::LTI::MembershipService do
  subject { described_class }
  let(:consumer_key)  { "valid_consumer_key" }
  let(:shared_secret) { "valid_shared_secret" }

  # Official LTI reference tool consumer specifically for testing purposes. Response will be stored in VCR.
  let(:endpoint) { "http://lti.tools/saltire/tc-membership.php/context/9hdod30uhcnf2me5qoee93ahr7" }

  describe "membership", :vcr do
    context "valid authentication" do
      let(:instance) { subject.new(endpoint, consumer_key, shared_secret) }

      it "gets all membership" do
        membership = instance.membership
        expect(membership).to_not be_empty

        first_membership = membership.first
        expect(first_membership).to be_an_instance_of(IMS::LTI::Models::MembershipService::Membership)
      end

      it "gets only instructors" do
        instructors = instance.instructors
        expect(instructors).to_not be_empty

        instructors.each do |i|
          expect(i.role).to include(a_string_matching(/Instructor/))
        end
      end

      it "gets only students" do
        students = instance.students
        expect(students).to_not be_empty

        students.each do |i|
          expect(i.role).to include(a_string_matching(/Student/)).or include(a_string_matching(/Learner/))
        end
      end
    end

    context "invalid authentication" do
      let(:instance) { subject.new(endpoint, "invalid" + consumer_key, "invalid" + shared_secret) }

      it "cannot get members" do
        expect { instance.membership }.to raise_error(Faraday::ClientError)
      end
    end
  end
end
