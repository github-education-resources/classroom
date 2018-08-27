# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupRepositoryCreationStatusChannel, type: :channel do
  let(:student) { classroom_student }

  it "subscribes to stream" do
    stub_connection current_user: student
    subscribe(group_id: 1, group_assignment_id: 1)
    expect(streams).to include(GroupRepositoryCreationStatusChannel.channel(group_id: 1, group_assignment_id: 1))
  end
end
