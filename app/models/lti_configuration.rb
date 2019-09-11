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
    moodle: "Moodle",
    sakai: "Sakai",
    other: "other"
  }, _prefix: true

  def lms_name(default_name: "Other learning management system")
    lms_settings.platform_name || default_name
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
      description: "Sync your GitHub Classroom organization with your learning management system.",
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
