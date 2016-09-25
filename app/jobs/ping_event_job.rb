# frozen_string_literal: true
class PingEventJob < ApplicationJob
  queue_as :ping_event

  def perform(payload_body)
    # Do Nothing Right now
  end
end
