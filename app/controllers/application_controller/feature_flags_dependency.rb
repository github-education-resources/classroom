# frozen_string_literal: true

class ApplicationController
  def ensure_team_management_flipper_is_enabled
    not_found unless team_management_enabled?
  end

  def dashboard_search_enabled?
    logged_in? && current_user.feature_enabled?(:dashboard_search)
  end
  helper_method :dashboard_search_enabled?

  def multiple_classrooms_per_org_enabled?
    logged_in? && current_user.feature_enabled?(:multiple_classrooms_per_org)
  end
  helper_method :multiple_classrooms_per_org_enabled?

  def public_assistant_landing_page_enabled?
    GitHubClassroom.flipper[:public_assistant_landing_page].enabled?
  end
  helper_method :public_assistant_landing_page_enabled?

  def assistant_landing_page_enabled?
    logged_in? && current_user.feature_enabled?(:assistant_landing_page)
  end
  helper_method :assistant_landing_page_enabled?

  def public_home_v2_enabled?
    GitHubClassroom.flipper[:public_home_v2].enabled?
  end
  helper_method :public_home_v2_enabled?

  def home_v2_enabled?
    logged_in? && current_user.feature_enabled?(:home_v2)
  end
  helper_method :home_v2_enabled?

  def team_management_enabled?
    logged_in? && current_user.feature_enabled?(:team_management)
  end
  helper_method :team_management_enabled?

  def search_assignments_enabled?
    logged_in? && current_user.feature_enabled?(:search_assignments)
  end
  helper_method :search_assignments_enabled?

  def lti_launch_enabled?
    GitHubClassroom.flipper[:lti_launch].enabled?
  end
  helper_method :lti_launch_enabled?
end
