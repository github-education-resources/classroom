# frozen_string_literal: true

class ApplicationController
  def ensure_team_management_flipper_is_enabled
    not_found unless team_management_enabled?
  end

  def team_management_enabled?
    logged_in? && current_user.feature_enabled?(:team_management)
  end
  helper_method :team_management_enabled?

  def classroom_visibility_enabled?
    logged_in? && current_user.feature_enabled?(:classroom_visibility)
  end
  helper_method :classroom_visibility_enabled?

  def onboarding_redesign_enabled?
    GitHubClassroom.flipper[:onboarding_redesign].enabled? || (logged_in? && current_user.feature_enabled?(:onboarding_redesign))
  end
  helper_method :onboarding_redesign_enabled?
end
