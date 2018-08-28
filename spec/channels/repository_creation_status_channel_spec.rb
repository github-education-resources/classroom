# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepositoryCreationStatusChannel, type: :channel do
  let(:student) { classroom_student }

  it "subscribes to stream" do
    stub_connection current_user: student
    subscribe
    expect(streams).to include(RepositoryCreationStatusChannel.channel(user_id: student.id))
  end
end
