# frozen_string_literal: true

module Octopoller
  class TimeoutError < StandardError; end
  class TooManyAttemptsError < StandardError; end

  # Polls until success
  # Re-runs when the block returns `:re_poll`
  #
  # wait    - The time delay in seconds between polls (default is 1 second)
  # timeout - The maximum number of seconds the poller will run (default is 15 seconds)
  # yield   - A block that will execute, and if `:re_poll` is returned it will re-run
  #         - Re-runs until success or the timeout is reached
  # raise   - Raises an Octopoller::TimeoutError if the timeout is reached
  def poll(wait: 1.second, timeout: 15.seconds)
    raise ArgumentError, "Cannot wait backwards in time" if wait.negative?
    raise ArgumentError, "Timed out without even being able to try" if timeout.negative?

    start = Time.now.utc
    while Time.now.utc < start + timeout
      block_value = yield
      return block_value unless block_value == :re_poll
      sleep wait
    end
    raise TimeoutError, "Polling timed out paitently"
  end

  # Tries until success
  # Re-runs when the block returns `:retry`
  #
  # wait      - The time delay in seconds between attempts (default is 1 second)
  #           - When given the argument `:exponentially` the action will be retried with exponetial backoff
  # attempts  - The maximum number of attempts the action will be performed (default is 15)
  # yield     - A block that will execute, and if `:retry` is returned it will re-run the action
  #           - re-run the action until success or the max number of attempts is reached
  # raise     - Raises an Octopoller::TooManyTriesError if the max number of attempts is reached
  #
  # rubocop:disable MethodLength
  # rubocop:disable CyclomaticComplexity
  # rubocop:disable PerceivedComplexity
  def try(wait: 1.second, attempts: 15)
    exponential_backoff = wait == :exponentially
    raise ArgumentError, "Cannot wait backwards in time" unless exponential_backoff || wait.positive?
    raise ArgumentError, "Cannot try something a negative number of attempts" if attempts.negative?
    raise ArgumentError, "Cannot try something zero attempts" if attempts.zero?

    wait = 0.5.seconds if exponential_backoff
    attempts.times do
      block_value = yield
      return block_value unless block_value == :retry
      sleep wait
      wait *= 2 if exponential_backoff
    end
    raise TooManyAttemptsError, "Tried maximum number of attempts"
  end
  # rubocop:enable MethodLength
  # rubocop:enable CyclomaticComplexity
  # rubocop:enable PerceivedComplexity

  module_function :poll
  module_function :try
end
