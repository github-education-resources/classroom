# frozen_string_literal: true

module Sidekiq
  class ChewyMiddleware
    def initialize(strategy = :atomic)
      @strategy = strategy
    end

    def call(_, _, _)
      Chewy.strategy(@strategy) do
        yield
      end
    end
  end
end
