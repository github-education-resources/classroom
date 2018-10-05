# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Wraping `ApplicationJob` in a `Chewy.request_strategy` prevents us from getting `Chewy::UndefinedUpdateStrategy`
  # For details see the thread: https://github.com/education/classroom/pull/1588#discussion_r219500289
  around_perform do |_, block|
    Chewy.strategy(:active_job) do
      block.call
    end
  end
end
