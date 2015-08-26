class PushStarterCodeJob < ActiveJob::Base
  queue_as :starter_code

  def perform(assignment_repository, starter_code_repository)
    assignment_repository.get_starter_code_from(starter_code_repository.full_name)
  end
end
