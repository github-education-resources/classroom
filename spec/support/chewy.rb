# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    Chewy.strategy(:bypass)
  end
end
