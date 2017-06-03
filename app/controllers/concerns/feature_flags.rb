# frozen_string_literal: true

module FeatureFlags
  extend ActiveSupport::Concern

  def ensure_team_management_flipper_is_enabled
    not_found unless team_management_enabled?
  end

  def ensure_student_identifier_flipper_is_enabled
    not_found unless student_identifier_enabled?
  end

  def student_identifier_enabled?
    logged_in? && current_user.feature_enabled?(:student_identifier)
  end

  def team_management_enabled?
    logged_in? && current_user.feature_enabled?(:team_management)
  end
end
