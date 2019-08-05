# frozen_string_literal: true

class LtiConfiguration < ApplicationRecord
  belongs_to :organization

  validates :lms_type, presence: true

  delegate :icon, to: :lms_settings, prefix: :lms
  delegate :lti_version, to: :lms_settings
  delegate :supports_autoconfiguration?, to: :lms_settings
  delegate :supports_membership_service?, to: :lms_settings

  delegate :context_membership_url, to: :lms_settings
  delegate :context_membership_body_params, to: :lms_settings

  enum lms_type: {
    canvas: "Canvas",
    brightspace: "Brightspace",
    moodle: "Moodle",
    other: "other"
  }, _prefix: true

  def self.find_by_auth_hash(hash)
    consumer_key = hash.credentials.token
    find_by(consumer_key: consumer_key)
  end

  def lms_name(default_name: "Other Learning Management System")
    lms_settings.platform_name || default_name
  end

  # TODO: this method is more or less entirely unnecessary (and doesn't belong here, really).
  # Remove it when possible.
  def context_membership_url(use_cache: true)
    cached_value = self[:context_membership_url] if use_cache
    return cached_value if cached_value

    message = launch_message
    return nil unless message

    membership_url = message.custom_params[lms_settings.context_memberships_url_key]
    return nil unless membership_url

    self[:context_membership_url] = membership_url
    save!

    membership_url
  end

  def cached_launch_message_nonce=(value)
    message_store = GitHubClassroom.lti_message_store(consumer_key: consumer_key)
    message_store.delete_message(cached_launch_message_nonce)

    super(value)
  end

  def launch_message
    return nil unless cached_launch_message_nonce
    message_store = GitHubClassroom.lti_message_store(consumer_key: consumer_key)
    message_store.get_message(cached_launch_message_nonce)
  end

  def xml_configuration(launch_url)
    return unless supports_autoconfiguration?

    builder = GitHubClassroom::LTI::ConfigurationBuilder.new("GitHub Classroom", launch_url)

    builder.add_attributes(
      description: "Sync your GitHub Classroom organization with your Learning Management System.",
      icon: "https://classroom.github.com/favicon.ico",
      vendor_name: "GitHub Classroom",
      vendor_url: "https://classroom.github.com/"
    )

    builder.add_vendor_attributes(lms_settings.vendor_domain, lms_settings.vendor_attributes)
    builder.to_xml
  end

  private

  def lms_settings
    return LtiConfiguration::GenericSettings.new(launch_message) if lms_type.blank?
    return LtiConfiguration::GenericSettings.new(launch_message) if lms_type_other?

    klass = "LtiConfiguration::#{lms_type.capitalize}Settings"
    klass.constantize.new(launch_message)
  end
end
