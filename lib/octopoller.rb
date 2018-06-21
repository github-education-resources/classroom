# frozen_string_literal: true

module Octopoller
  class TimeoutError < StandardError; end

  # Polls until a sccuessfu
  # Continues to poll when an error is caight
  #
  # wait - The time delay in seconds between polls (default is 1)
  # timeout - The maximum number of seconds the poller poll (default is 15)
  # error_handler - A proc that will be passed an instance of each raised error
  # yield - A block that will execute, and if it raises an error it will re-run until success or the timeout is reached
  # raise - Raises a Octopoller::TimeoutError if the timout is reached
  #
  # rubocop:disable MethodLength
  def poll(wait: 1, timeout: 15, error_handler: nil)
    raise ArgumentError, "Cannot poll backwards in time" if wait.negative?
    raise ArgumentError, "Timed out without even being able to try" if timeout.negative?

    start = Time.now.utc
    while Time.now.utc < start + timeout
      begin
        return yield
      rescue => e
        error_handler&.call(e) if error_handler
        sleep wait
      end
    end
    raise TimeoutError, "Polling timed out paitently"
  end
  # rubocop:enable MethodLength

  module_function :poll
end
