# frozen_string_literal: true

# rubocop:disable ClassAndModuleChildren
module GitHubClassroom::LTI::Models::MembershipExtension
  class Member < IMS::LTI::Models::LTIModel
    add_attributes :person_name_family, :person_name_given, :person_sourcedid, :user_id
    add_attribute :name,  json_key: "person_name_full"
    add_attribute :email, json_key: "person_contact_email_primary"
    add_attribute :role,  json_key: "roles"
  end
end
# rubocop:enable ClassAndModuleChildren
