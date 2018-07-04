# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:teacher) { classroom_teacher }

  it "connects successfully" do
    ActionCable::Connection::TestRequest
      .any_instance.stub(:session)
      .and_return(user_id: teacher.id)

    connect
    expect(connection.current_user).to eq(teacher)
  end

  it "rejects connection" do
    expect { connect }.to have_rejected_connection
  end
end
