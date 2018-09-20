# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  around_perform do |job, block|
    Chewy.strategy(:active_job) do
      block.call
    end
  end
end
