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

  def multiple_classrooms_per_org_enabled?
    logged_in? && current_user.feature_enabled?(:multiple_classrooms_per_org)
  end
  helper_method :multiple_classrooms_per_org_enabled?

  def team_management_enabled?
    logged_in? && current_user.feature_enabled?(:team_management)
  end
  helper_method :team_management_enabled?

  def search_assignments_enabled?
    logged_in? && current_user.feature_enabled?(:search_assignments)
  end
  helper_method :search_assignments_enabled?

  def lti_launch_enabled?
    GitHubClassroom.flipper[:lti_launch].enabled? || (logged_in? && current_user.feature_enabled?(:lti_launch))
  end
  helper_method :lti_launch_enabled?

  def unified_repo_creators_enabled?
    GitHubClassroom.flipper[:unified_repo_creators].enabled?
  end
  helper_method :unified_repo_creators_enabled?
end
