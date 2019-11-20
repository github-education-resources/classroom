# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupRepositoryCreationStatusChannel, type: :channel do
  let(:student) { classroom_student }

  it "subscribes to stream" do
    stub_connection current_user: student
    subscribe(group_id: 1, group_assignment_id: 1)
    assert_has_stream "group_repository_creation_status_1_1"
  end
end
