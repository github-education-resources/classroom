# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LastActiveJob, type: :job do
  let(:user) { create(:user) }

  before(:each) do
    @time = (Time.current + 600).to_i
  end

  it 'uses the :last_active_at queue' do
    assert_performed_with(job: LastActiveJob, args: [user, @time], queue: 'last_active') do
      LastActiveJob.perform_later(user, @time)
    end
  end

  it 'updates the last_active_at attribute' do
    LastActiveJob.perform_now(user, @time)
    expect(user.last_active_at).to eql(Time.zone.at(@time))
  end

  it 'does not change the updated_at column' do
    LastActiveJob.perform_now(user, @time)
    expect(user.last_active_at).to_not eql(user.updated_at)
  end
end
