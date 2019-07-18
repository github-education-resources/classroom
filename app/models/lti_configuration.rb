# frozen_string_literal: true

class LtiConfiguration < ApplicationRecord
  belongs_to :organization

  def self.find_by_auth_hash(hash)
    consumer_key = hash.credentials.token
    find_by(consumer_key: consumer_key)
  end

  def context_membership_url(use_cache: true, nonce: nil)
    cached_value = self[:context_membership_url]
    return cached_value if use_cache && cached_value

    message_store = GitHubClassroom.lti_message_store(consumer_key: consumer_key)
    message = message_store.get_message(nonce)
    return nil unless message

    membership_url = message.custom_params["custom_context_memberships_url"]
    return nil unless membership_url

    self[:context_membership_url] = membership_url
    membership_url
  end
end
