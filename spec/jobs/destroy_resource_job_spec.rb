# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DestroyResourceJob, type: :job do
  let(:organization) { create(:organization) }

  it 'destroys the resource' do
    assert_performed_with(job: DestroyResourceJob, args: [organization], queue: 'trash_can') do
      DestroyResourceJob.perform_later(organization)
    end
  end
end
