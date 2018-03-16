# frozen_string_literal: true

class Assignment
  class RepositorySetupJob < ApplicationJob
    queue_as :assignment

    def perform
      # rely on porter if the assignment has a starter code
    end
  end
end
