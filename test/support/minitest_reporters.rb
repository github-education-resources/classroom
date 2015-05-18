require 'minitest/reporters'

Minitest::Reporters.use!(
  Minitest::Reporters::ProgressReporter.new,
  ENV,
  Minitest.backtrace_filter)
