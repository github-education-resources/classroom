# frozen_string_literal: true

class ApplicationController
  def ensure_team_management_flipper_is_enabled
    not_found unless team_management_enabled?
  end

  def ensure_lti_launch_flipper_is_enabled
    not_found unless lti_launch_enabled?
  end

  def ensure_google_classroom_roster_import_is_enabled
    not_found unless google_classroom_roster_import_enabled?
  end

  def google_classroom_roster_import_enabled?
    logged_in? && current_user.feature_enabled?(:google_classroom_roster_import)
  end
  helper_method :google_classroom_roster_import_enabled?

  def team_management_enabled?
    logged_in? && current_user.feature_enabled?(:team_management)
  end
  helper_method :team_management_enabled?

  def lti_launch_enabled?
    GitHubClassroom.flipper[:lti_launch].enabled? || (logged_in? && current_user.feature_enabled?(:lti_launch))
  end
  helper_method :lti_launch_enabled?

  def classroom_visibility_enabled?
    logged_in? && current_user.feature_enabled?(:classroom_visibility)
  end
  helper_method :classroom_visibility_enabled?

  def onboarding_redesign_enabled?
    GitHubClassroom.flipper[:onboarding_redesign].enabled? || (logged_in? && current_user.feature_enabled?(:onboarding_redesign))
  end
  helper_method :onboarding_redesign_enabled?
end
