module ParameterFiltering
  SANITIZED_VALUE = "[FILTERED]".freeze

  # If you want a parameter's value to show up in logs and in failbot reports (Haystack/Sentry),
  # it must be added to this list.
  ALLOWLISTED_PARAMETERS = %w[
    repository_id
  ]

  ALLOWLISTED_PARAMETERS_REGEX = /\A(#{ALLOWLISTED_PARAMETERS.join("|")})\z/

  def self.filtered_params_proc
    lambda do |key, value|
      unless key =~ ALLOWLISTED_PARAMETERS_REGEX
        value.replace(SANITIZED_VALUE) if value.respond_to?(:replace)
      end
    end
  end
end
