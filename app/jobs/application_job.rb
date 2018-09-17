# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  around_perform do |_, block|
    Chewy.strategy(:atomic) do
      block.call
    end
  end
end
