# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
module GitHubClassroom::LTI::Models::MembershipExtension
  class StatusInfo < IMS::LTI::Models::LTIModel
    add_attributes :codemajor, :codeminor, :severity
  end
end
# rubocop:enable ClassAndModuleChildren
