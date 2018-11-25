# frozen_string_literal: true

module Prerelease
  class BadgeView < ViewModel
    include ApplicationHelper

    attr_reader :feature_flag
    attr_reader :public_name
    attr_reader :feedback_url

    # Should the prerelease badge be displayed to the current user?
    #
    # Note: The badge is not displayed if the feature is disabled, or if
    # the feature has been fully released (and thus is no-longer pre-release)
    def display_badge?
      return false unless logged_in?
      current_user.feature_enabled?(feature_flag)
    end
  end
end