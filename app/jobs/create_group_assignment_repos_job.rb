class CreateGroupAssignmentReposJob < ActiveJob::Base
  def perform(group_assignment_id)
    group_assignment = GroupAssignment.find(group_assignment_id)

    return unless group_assignment.starter_code?

    group_assignment.grouping.groups.each do |group|
      GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
    end
  end
end
