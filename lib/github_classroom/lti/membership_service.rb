# frozen_string_literal: true

module GitHubClassroom
  module LTI
    class MembershipService
      include RequestSigning

      def initialize(endpoint, consumer_key, secret)
        @endpoint = endpoint
        @consumer_key = consumer_key
        @secret = secret
      end

      def students
        filtered_membership(roles: %w[Student Learner])
      end

      def instructors
        filtered_membership(roles: ["Instructor"])
      end

      def membership
        req_headers = { "Accept": "application/vnd.ims.lis.v2.membershipcontainer+json" }
        response = signed_request(@endpoint, @consumer_key, @secret, headers: req_headers).get

        json_membership = JSON.parse(response.body)
        parsed_membership = parse_membership(json_membership)

        parsed_membership
      end

      private

      def filtered_membership(roles: nil)
        unfiltered_membership = membership
        return unfiltered_membership unless roles

        unfiltered_membership.select do |membership|
          # LMS is allowed to prefix a role with anything it wants
          # so the filter method simply matches on substrings
          roles.any? do |desired_role|
            membership.role.any? do |actual_role|
              actual_role.include? desired_role
            end
          end
        end
      end

      def parse_membership(json_membership)
        unparsed_memberships = json_membership.dig("pageOf", "membershipSubject", "membership")
        unparsed_memberships.map do |unparsed_membership|
          membership_hash = unparsed_membership.deep_transform_keys { |key| key.underscore.to_sym }
          member_hash = membership_hash[:member]

          parsed_member = IMS::LTI::Models::MembershipService::LISPerson.new(member_hash)
          membership_hash[:member] = parsed_member

          IMS::LTI::Models::MembershipService::Membership.new(membership_hash)
        end
      end
    end
  end
end
