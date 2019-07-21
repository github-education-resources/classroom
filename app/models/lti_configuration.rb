# frozen_string_literal: true

class LtiConfiguration < ApplicationRecord
  belongs_to :organization

  enum lms_type: {
    canvas: "Canvas",
    blackboard: "Blackboard",
    brightspace: "Brightspace",
    moodle: "Moodle",
    other: "other"
  }, _prefix: true

  def lms_name(default_name: "Other Learning Management System")
    return default_name if lms_type_other?
    LtiConfiguration.lms_types[lms_type]
  end

  def self.find_by_auth_hash(hash)
    consumer_key = hash.credentials.token
    find_by(consumer_key: consumer_key)
  end

  def context_membership_url(use_cache: true, nonce: nil)
    cached_value = self[:context_membership_url] if use_cache
    return cached_value if cached_value

    message_store = GitHubClassroom.lti_message_store(consumer_key: consumer_key)
    message = message_store.get_message(nonce)
    return nil unless message

    membership_url = message.custom_params["custom_context_memberships_url"]
    return nil unless membership_url

    self[:context_membership_url] = membership_url
    save!

    membership_url
  end
end
