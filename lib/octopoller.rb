# frozen_string_literal: true

module Octopoller
  class TimeoutError < StandardError; end

  # Polls until success
  # Re-runs when an error is caught
  #
  # wait - The time delay in seconds between polls (default is 1 second)
  # timeout - The maximum number of seconds the poller will run (default is 15 seconds)
  # error_handler - A proc that will run with each instance of an error
  # yield - A block that will execute, and if it raises an error it will re-run until success or the timeout is reached
  # raise - Raises an Octopoller::TimeoutError if the timeout is reached
  # rubocop:disable AbcSize
  def poll(wait: 1.second, timeout: 15.seconds)
    raise ArgumentError, "Cannot poll backwards in time" if wait.negative?
    raise ArgumentError, "Timed out without even being able to try" if timeout.negative?

    start = Time.now.utc
    while Time.now.utc < start + timeout
      block_value = yield
      return block_value unless block_value == :re_poll
      sleep wait
    end
    raise TimeoutError, "Polling timed out paitently"
  end
  # rubocop:enable AbcSize

  module_function :poll
end
