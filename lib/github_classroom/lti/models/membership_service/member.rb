# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
module GitHubClassroom::LTI::Models::MembershipService
  class Member < IMS::LTI::Models::LTIModel
    add_attributes :name, :email
    add_attribute :user_id, json_key: "userId"
    add_attribute :source_id, json_key: "sourcedId"
    add_attribute :family_name, json_key: "familyName"
    add_attribute :given_name, json_key: "givenName"
    add_attribute :type, json_key: "@type"
  end
end
# rubocop:enable ClassAndModuleChildren
