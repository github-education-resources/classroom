# frozen_string_literal: true

class DestroyResourceJob < ApplicationJob
  queue_as :default

  def perform(resource)
    resource.destroy
  end
end
