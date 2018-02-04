# frozen_string_literal: true

class BoomJob < ApplicationJob
  queue_as :boom

  def perform(*)
    raise "BOOM"
  end
end
