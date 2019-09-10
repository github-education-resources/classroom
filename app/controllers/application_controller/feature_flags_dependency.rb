# frozen_string_literal: true

class ApplicationController
  def ensure_team_management_flipper_is_enabled
    not_found unless team_management_enabled?
  end

  def ensure_lti_launch_flipper_is_enabled
    not_found unless lti_launch_enabled?
  end

  def team_management_enabled?
    logged_in? && current_user.feature_enabled?(:team_management)
  end
  helper_method :team_management_enabled?

  def archive_classrooms_enabled?
    logged_in? && current_user.feature_enabled?(:archive_classrooms)
  end
  helper_method :archive_classrooms_enabled?

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
