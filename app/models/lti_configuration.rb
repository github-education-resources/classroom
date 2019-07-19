# frozen_string_literal: true

class LtiConfiguration < ApplicationRecord
  belongs_to :organization

  enum lms_type: {
    canvas: 1,
    blackboard: 2,
    brightspace: 3,
    moodle: 4,
    other: 5
  }

  def self.find_by_auth_hash(hash)
    consumer_key = hash.credentials.token
    find_by(consumer_key: consumer_key)
  end
end
