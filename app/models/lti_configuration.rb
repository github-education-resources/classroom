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
end
