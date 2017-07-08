# frozen_string_literal: true

if Rails.env.production?
  ActiveSupport.on_load :active_job do
    class ActiveJob::Logging::LogSubscriber
      private def args_info(job) # rubocop:disable UnusedMethodArgument
        ''
      end
    end
  end
end
