# frozen_string_literal: true

module Octopoller
  class TimeoutError < StandardError; end

  def poll(wait: 1, timeout: 15, error_handler: nil, &block)
    if wait < 0
      raise ArgumentError, "Cannot poll backwards in time"
    end
    if timeout < 0
      raise ArgumentError, "Timed out without even being able to try"
    end

    start = Time.now
    while Time.now < start + timeout
      begin
        return block.call
      rescue Exception => e
        unless error_handler.nil?
          error_handler.call(e)
        end
        sleep wait
      end
    end
    raise TimeoutError, "Polling timed out paitently"
  end

  module_function :poll
end
