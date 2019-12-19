# frozen_string_literal: true

class ApplicationController
  def classroom_visibility_enabled?
    logged_in? && current_user.feature_enabled?(:classroom_visibility)
  end
  helper_method :classroom_visibility_enabled?

  def onboarding_redesign_enabled?
    GitHubClassroom.flipper[:onboarding_redesign].enabled? || (logged_in? && current_user.feature_enabled?(:onboarding_redesign))
  end
  helper_method :onboarding_redesign_enabled?
end
