# frozen_string_literal: true

require "rails_helper"

RSpec.describe LastActiveJob, type: :job do
  let(:user) { create(:user) }

  before(:each) do
    Timecop.freeze(Time.zone.now)
    @time = (Time.zone.now + 600).to_i
  end

  after(:each) do
    Timecop.return
  end

  it "uses the :low queue" do
    ActiveJob::Base.queue_adapter = :test
    expect do
      LastActiveJob.perform_later(user.id, @time)
    end.to have_enqueued_job.on_queue("low")
  end

  it "updates the last_active_at attribute" do
    LastActiveJob.perform_now(user.id, @time)
    expect(user.reload.last_active_at).to eql(Time.zone.at(@time))
  end

  it "does not change the updated_at column" do
    LastActiveJob.perform_now(user.id, @time)
    expect(user.reload.last_active_at).to_not eql(user.updated_at)
  end

  it "does not raise an error if the user is not longer present" do
    user_id = user.id
    user.destroy

    LastActiveJob.perform_now(user_id, @time)
  end
end
