# frozen_string_literal: true

class GroupAssignmentService
  def initialize(new_group_assignment_params, new_grouping_params)
    @grouping_id                 = new_group_assignment_params[:grouping_id]
    @new_group_assignment_params = new_group_assignment_params
    @new_grouping_params         = new_grouping_params
  end

  def build_group_assignment
    group_assignment = GroupAssignment.new(@new_group_assignment_params)

    if grouping_info_valid?
      group_assignment.grouping = Grouping.where(id: @grouping_id).first_or_create!(@new_grouping_params)
    end

    group_assignment.build_group_assignment_invitation
    group_assignment
  end

  def grouping_info_valid?
    @grouping_id.present? || @new_grouping_params[:title].present?
  end
end
