# frozen_string_literal: true

class ApplicationController
  class NotAuthorized < StandardError; end

  # rubocop:disable Metrics/MethodLength
  def flash_and_redirect_back_with_message(exception)
    flash[:error] = exception.message

    if flash[:error].blank?
      case exception
      when NotAuthorized
        flash[:error] = "You are not authorized to perform this action"
      when GitHub::Error, GitHub::Forbidden, GitHub::NotFound
        flash[:error] = "Uh oh, an error has occurred."
      end
    end

    GitHubClassroom.statsd.increment("exception.swallowed", tags: [exception.class.to_s])

    redirect_back(fallback_location: root_path)
  end
  # rubocop:enable Metrics/MethodLength

  def send_to_statsd_and_reraise(exception)
    GitHubClassroom.statsd.increment("exception.raise", tags: [exception.class.to_s])
    raise exception
  end
end
