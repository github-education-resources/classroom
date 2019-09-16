# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
module GitHubClassroom::LTI::Models::MembershipExtension
  class MessageResponse < IMS::LTI::Models::LTIModel
    add_attribute :lti_message_type

    add_attribute :membership, json_key: "members", relation: "GitHubClassroom::LTI::Models::MembershipExtension::Membership"
    add_attribute :status_info, json_key: "statusinfo", relation: "GitHubClassroom::LTI::Models::MembershipExtension::StatusInfo"
  end
end
# rubocop:enable ClassAndModuleChildren
