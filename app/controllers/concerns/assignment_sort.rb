# frozen_string_literal: true

module AssignmentSort
  extend ActiveSupport::Concern

  ##
  # Sorts the given repositories (e.g. AssignmentRepo or GroupAssignmentRepo)
  # by the ordering given in sort_modes. Note, because ActiveRecord_Relation cannot 
  # do arbitrary sorting, an Array, and not an ActiveRecord_Relation, is returned.
  def sort_assignment_repos(repos, sort_modes, default_mode = sort_modes.keys.first)
    @current_sort_mode = params[:sort_assignment_repos_by] || default_mode

    if sort_modes[@current_sort_mode]
      repos.sort_by &sort_modes[@current_sort_mode]
    else
      repos.to_a
    end
  end
end
