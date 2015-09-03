class GroupAssignmentService
  def initialize(new_group_assignment_params, new_grouping_params)
    @new_group_assignment_params = new_group_assignment_params
    @new_grouping_params         = new_grouping_params
  end

  def create_group_assignment
    grouping = Grouping.find_by(id: @new_group_assignment_params[:grouping_id])
    grouping = Grouping.new(@new_grouping_params) unless grouping.present?

    group_assignment = GroupAssignment.new(@new_group_assignment_params)
    group_assignment.build_group_assignment_invitation

    if grouping.new_record?
      grouping.save!
      group_assignment.grouping = grouping
    end

    group_assignment.save!
    group_assignment
  end
end
