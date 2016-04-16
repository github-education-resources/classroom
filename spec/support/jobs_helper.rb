# frozen_string_literal: true
RSpec.configure do |config|
  config.include ActiveJob::TestHelper, type: :job
end
