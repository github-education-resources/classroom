# frozen_string_literal: true

module GitHubClassroom
  module LTI
    class MembershipService
      include Mixins::RequestSigning

      def initialize(endpoint, consumer_key, secret)
        @endpoint = endpoint
        @consumer_key = consumer_key
        @secret = secret
      end

      def students
        membership(roles: %w[Student Learner])
      end

      def instructors
        membership(roles: %w[Instructor Admin])
      end

      def membership(roles: [])
        req_headers = { "Accept": "application/vnd.ims.lis.v2.membershipcontainer+json" }
        request = signed_request(@endpoint, @consumer_key, @secret,
          query: { role: roles.join(",") },
          headers: req_headers)
        response = request.get

        json_membership = JSON.parse(response.body)
        parsed_membership = parse_membership(json_membership)

        parsed_membership
      end

      private

      def parse_membership(json_membership)
        unparsed_memberships = json_membership.dig("pageOf", "membershipSubject", "membership")
        raise "Unexpected json object given" unless unparsed_memberships

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
