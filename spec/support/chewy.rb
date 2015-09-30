RSpec.configure do |config|
  config.before(:suite) do
    Chewy.strategy(:bypass)
  end
end
