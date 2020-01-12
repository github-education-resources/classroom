# frozen_string_literal: true

class BoomJob < ApplicationJob
  queue_as :critical

  def perform(*)
    raise "BOOM"
  end
end
