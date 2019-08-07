# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
module GitHubClassroom::LTI::Models::MembershipService
  class Membership < IMS::LTI::Models::LTIModel
    add_attributes :status, :role
    add_attribute :member, relation: "GitHubClassroom::LTI::Models::MembershipService::Member"
  end
end
# rubocop:enable ClassAndModuleChildren
