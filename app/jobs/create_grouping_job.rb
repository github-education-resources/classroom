class CreateGroupingJob < ActiveJob::Base
  queue_as :default

  def perform(group_assignment, new_grouping_params)
    return if group_assignment.grouping.present?

    grouping = Grouping.new(new_grouping_params)
    grouping.save!

    group_assignment.grouping = grouping
    group_assignment.save!
  end
end
