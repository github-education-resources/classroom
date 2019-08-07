# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
module GitHubClassroom::LTI::Models::MembershipExtension
  class Membership < IMS::LTI::Models::LTIModel
    add_attribute :member, relation: "GitHubClassroom::LTI::Models::MembershipExtension::Member"

    def members
      [*@member]
    end
  end
end
# rubocop:enable ClassAndModuleChildren
