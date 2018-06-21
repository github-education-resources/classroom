# frozen_string_literal: true

module Octopoller
  class TimeoutError < StandardError; end

  # Polls until success
  # Re-runs when an error is caught
  #
  # wait - The time delay in seconds between polls (default is 1)
  # timeout - The maximum number of seconds the poller will run (default is 15)
  # error_handler - A proc that will run with each instance of an error
  # yield - A block that will execute, and if it raises an error it will re-run until success or the timeout is reached
  # raise - Raises an Octopoller::TimeoutError if the timeout is reached
  #
  # rubocop:disable MethodLength
  def poll(wait: 1, timeout: 15, error_handler: nil)
    raise ArgumentError, "Cannot poll backwards in time" if wait.negative?
    raise ArgumentError, "Timed out without even being able to try" if timeout.negative?

    start = Time.now.utc
    while Time.now.utc < start + timeout
      begin
        return yield
      rescue => e # rubocop:disable RescueStandardError
        error_handler&.call(e) if error_handler
        sleep wait
      end
    end
    raise TimeoutError, "Polling timed out paitently"
  end
  # rubocop:enable MethodLength

  module_function :poll
end
