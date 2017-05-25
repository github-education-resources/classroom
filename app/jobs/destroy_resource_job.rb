# frozen_string_literal: true

class DestroyResourceJob < ApplicationJob
  queue_as :trash_can

  def perform(resource)
    resource.destroy
  end
end
