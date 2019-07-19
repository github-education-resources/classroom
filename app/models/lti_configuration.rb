# frozen_string_literal: true

class LtiConfiguration < ApplicationRecord
  belongs_to :organization

  enum lms_type: {
    canvas: "canvas",
    blackboard: "blackboard",
    brightspace: "brightspace",
    moodle: "moodle",
    other: "other"
  }

  def self.find_by_auth_hash(hash)
    consumer_key = hash.credentials.token
    find_by(consumer_key: consumer_key)
  end
end
