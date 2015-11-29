module Sidekiq
  class ChewyMiddleware
    def initialize(strategy = :atomic)
      @strategy = strategy
    end

    def call(worker, msg, queue)
      Chewy.strategy(@strategy) do
        yield
      end
    end
  end
end
