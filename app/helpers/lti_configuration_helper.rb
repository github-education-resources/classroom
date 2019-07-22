# frozen_string_literal: true

module LtiConfigurationHelper
  def lms_type_select_options
    LtiConfiguration.lms_types.map do |k, v|
      if k == "other"
        ["Other Learning Management System", k]
      else
        [v, k]
      end
    end
  end
end
