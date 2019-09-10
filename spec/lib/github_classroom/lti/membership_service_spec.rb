# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::LTI::MembershipService do
  subject { described_class }
  let(:consumer_key)  { "valid_consumer_key" }
  let(:shared_secret) { "valid_shared_secret" }

  describe "membership service (LTI 1.1)", :vcr do
    # Official LTI reference tool consumer specifically for testing purposes. Response will be stored in VCR.
    let(:endpoint) { "http://ltiapps.net/test/tc-memberships.php/context/bcde6a55f4cad71bb7865a04a57823ec" }

    context "valid authentication" do
      let(:instance) { subject.new(endpoint, consumer_key, shared_secret) }

      it "gets all membership" do
        membership = instance.membership
        expect(membership).to_not be_empty

        expected_klass = GitHubClassroom::LTI::Models::CourseMember
        member = membership.first
        expect(member).to be_an_instance_of(expected_klass)
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

      context "invalid json is given" do
        before do
          instance.stub(:fetch_raw_membership) do
            "sdfsdf"
          end
        end

        it "raises error and logs" do
          allow(Rails.logger).to receive(:error)
          expect { instance.students }.to raise_error(JSON::ParserError)
          expect(Rails.logger).to have_received(:error).with("raw_data: sdfsdf")
        end
      end

      context "pagination" do
        let(:mock_raw_body) { { nextPage: endpoint }.to_json }

        before(:each) do
          # Because we are stubbing getting a paginated response,
          # we need to unstub it after so we don't get stuck in an infinite loop
          # (since we'd be continuously fetching the next page)
          instance.stub(:fetch_raw_membership) do
            instance.unstub(:fetch_raw_membership)
            mock_raw_body
          end

          instance.stub(:parse_membership) { [GitHubClassroom::LTI::Models::CourseMember.new] }
        end

        it "gets the membership for each page" do
          expect(instance).to receive(:membership).and_call_original.twice
          instance.membership
        end

        it "collects all pages of results into one list" do
          membership = instance.membership
          expect(membership.length).to eq(2)
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

  describe "membership extension (LTI 1.0)", :vcr do
    let(:endpoint) { "https://trysakai.longsight.com/imsblis/service/" }
    let(:body_params) { { "id": "4d0a6e23e6902927ff0ad4e7869f7f5cb3c5b962cd7fbb796d87a4ceab90fadd:::ce59ead6-026b-4ba5-9464-568e131c0a77:::content:2586" } }

    context "valid authentication" do
      let(:instance) { subject.new(endpoint, consumer_key, shared_secret, lti_version: 1.0) }

      it "gets membership" do
        membership = instance.membership(body_params: body_params)
        expect(membership).to_not be_empty

        expected_klass = GitHubClassroom::LTI::Models::CourseMember
        member = membership.first
        expect(member).to be_an_instance_of(expected_klass)
      end
    end
  end
end
