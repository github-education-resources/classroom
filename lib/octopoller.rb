# frozen_string_literal: true

module Octopoller
  class TimeoutError < StandardError; end

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
