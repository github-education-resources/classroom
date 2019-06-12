# frozen_string_literal: true

module AssignmentSort
  extend ActiveSupport::Concern

  def sort_assignment_repos(repos, sort_modes)
    @current_sort_mode = params[:sort_assignment_repos_by] || sort_modes.keys.first

    if sort_modes[@current_sort_mode]
      repos.sort_by &sort_modes[@current_sort_mode]
    else
      repos
    end
  end
end
