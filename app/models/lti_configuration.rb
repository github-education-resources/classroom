# frozen_string_literal: true

class LtiConfiguration < ApplicationRecord
  belongs_to :organization

  enum lms_type: [
    :other,
    :blackboard,
    :canvas,
    :moodle,
    :brightspace,
  ]

  def self.find_by_auth_hash(hash)
    consumer_key = hash.credentials.token
    find_by(consumer_key: consumer_key)
  end
end
