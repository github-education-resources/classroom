# frozen_string_literal: true

module ParameterFiltering
  SANITIZED_VALUE = "[FILTERED]"

  # If you want a parameter's value to show up in logs and in failbot reports (Haystack/Sentry),
  # it must be added to this list.
  ALLOWLISTED_PARAMETERS = %w[
    repository_id
  ].freeze

  ALLOWLISTED_PARAMETERS_REGEX = /\A(#{ALLOWLISTED_PARAMETERS.join("|")})\z/

  def self.filtered_params_proc
    lambda do |key, value|
      unless ALLOWLISTED_PARAMETERS_REGEX.match?(key)
        value.replace(SANITIZED_VALUE) if value.respond_to?(:replace)
      end
    end
  end

  def self.filter(params)
    filter = ActionDispatch::Http::ParameterFilter.new([filtered_params_proc])
    filter.filter(params)
  end

  def self.sanitize_urls(message)
    message.gsub(/https?:\/\/[\S]+/) do |url|
      uri = URI.parse(url)
      # Filter out path, query params, etc in case they are sensitive
      "#{uri.scheme}://#{uri.host}/[PATH_FILTERED]"
    end
  end
end
