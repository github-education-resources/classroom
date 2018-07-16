# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepositoryCreationStatusChannel, type: :channel do
  let(:teacher) { classroom_teacher }

  it "subscribes to stream" do
    stub_connection current_user: teacher
    subscribe
    expect(streams).to include(RepositoryCreationStatusChannel.channel(user_id: teacher.id))
  end
end
