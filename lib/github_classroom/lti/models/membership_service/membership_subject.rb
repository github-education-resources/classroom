# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
module GitHubClassroom::LTI::Models::MembershipService
  class MembershipSubject < IMS::LTI::Models::LTIModel
    add_attribute :membership, relation: "GitHubClassroom::LTI::Models::MembershipService::Membership"

    add_attribute :context, json_key: "contextId"
    add_attribute :id, json_key: "@id"
    add_attribute :type, json_key: "@type"

    def memberships
      [*@membership]
    end
  end
end
# rubocop:enable ClassAndModuleChildren
