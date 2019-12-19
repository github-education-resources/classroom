# frozen_string_literal: true

class ApplicationController
  def onboarding_redesign_enabled?
    GitHubClassroom.flipper[:onboarding_redesign].enabled? || (logged_in? && current_user.feature_enabled?(:onboarding_redesign))
  end
  helper_method :onboarding_redesign_enabled?
end
