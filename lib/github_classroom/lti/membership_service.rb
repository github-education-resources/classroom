# frozen_string_literal: true

module GitHubClassroom
  module LTI
    class MembershipService
      include Mixins::RequestSigning

      def initialize(context_membership_url, consumer_key, shared_secret, lti_version: 1.1)
        @context_membership_url = context_membership_url
        @consumer_key = consumer_key
        @secret = shared_secret
        @lti_version = lti_version
      end

      def students(body_params: nil)
        membership(roles: %w[Student Learner], body_params: body_params)
      end

      def instructors(body_params: nil)
        membership(roles: %w[Instructor], body_params: body_params)
      end

      def membership(roles: [], body_params: nil)
        req = membership_request(roles, body_params)
        response = send_request(req)

        parse_membership(response.body)
      end

      private

      def membership_request(roles, body_params)
        if @lti_version == 1.1
          accept_header = { "Accept": "application/vnd.ims.lis.v2.membershipcontainer+json" }
          role_query = { role: roles.join(",") }

          lti_request(@context_membership_url, method: :get, headers: accept_header, query: role_query)
        elsif @lti_version == 1.0
          body = body_params.merge(lti_message_type: "basic-lis-readmembershipsforcontext", lti_version: "LTI-1p0")

          lti_request(@context_membership_url, method: :post, body: body, lti_version: 1.0)
        end
      end

      def parse_membership(raw_data)
        if @lti_version == 1.1
          parse_membership_service(raw_data)
        elsif @lti_version == 1.0
          parse_membership_extension(raw_data)
        end
      end

      # LTI 1.1 (and up) responses
      def parse_membership_service(raw_data)
        json_membership = JSON.parse(raw_data)
        membership_subject_json = json_membership.dig("pageOf", "membershipSubject")
        raise JSON::ParserError unless membership_subject_json

        membership_subject = Models::MembershipService::MembershipSubject.from_json(membership_subject_json)
        membership_subject.memberships.map do |m|
          member = m.member
          Models::CourseMember.new(user_id: member.user_id, email: member.email, name: member.name, role: m.role)
        end
      end

      # LTI 1.0 responses
      def parse_membership_extension(raw_data)
        membership_hash = Hash.from_xml(raw_data)
        raise JSON::ParserError unless membership_hash["message_response"]
        message_response_json = membership_hash["message_response"].to_json

        message_response = Models::MembershipExtension::MessageResponse.from_json(message_response_json)
        message_response.membership.members.map do |m|
          Models::CourseMember.new(user_id: m.user_id, name: m.name, email: m.email, role: m.role)
        end
      end
    end
  end
end
