require 'rails_helper'

RSpec.describe CreateGroupingJob, type: :job do
  context 'Grouping does not exist' do
    let(:group_assignment)     { create(:group_assignment, grouping: nil)                           }
    let(:new_grouping_params)  { { organization: group_assignment.organization, title: 'Grouping' } }

    it 'creates a new grouping' do
      assert_performed_with(job: CreateGroupingJob, args: [group_assignment, new_grouping_params], queue: 'default') do
        CreateGroupingJob.perform_later(group_assignment, new_grouping_params)
      end

      expect(Grouping.all.count).to eql(1)
    end
  end
end
