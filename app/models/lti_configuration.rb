# frozen_string_literal: true

class LtiConfiguration < ApplicationRecord
  belongs_to :organization

  validates :lms_type, presence: true

  delegate :icon, to: :lms_settings, prefix: :lms
  delegate :supports_autoconfiguration, to: :lms_settings
  delegate :supports_membership_service, to: :lms_settings

  enum lms_type: {
    canvas: "Canvas",
    blackboard: "Blackboard",
    brightspace: "Brightspace",
    moodle: "Moodle",
    other: "other"
  }, _prefix: true

  def self.find_by_auth_hash(hash)
    consumer_key = hash.credentials.token
    find_by(consumer_key: consumer_key)
  end

  def lms_name(default_name: "Other Learning Management System")
    lms_settings.platform_name(default_name)
  end

  def context_membership_url(use_cache: true, nonce: nil)
    cached_value = self[:context_membership_url] if use_cache
    return cached_value if cached_value

    message_store = GitHubClassroom.lti_message_store(consumer_key: consumer_key)
    message = message_store.get_message(nonce)
    return nil unless message

    membership_url = message.custom_params[lms_settings.context_memberships_url_key]
    return nil unless membership_url

    self[:context_membership_url] = membership_url
    save!

    membership_url
  end

  private

  def lms_settings
    return LtiConfiguration::GenericSettings.new if lms_type.blank?
    return LtiConfiguration::GenericSettings.new if lms_type_other?

    klass = "LtiConfiguration::#{lms_type.capitalize}Settings"
    klass.constantize.new
  end
end
