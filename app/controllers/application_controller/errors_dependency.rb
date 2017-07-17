# frozen_string_literal: true

class ApplicationController
  class NotAuthorized < StandardError; end

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

    redirect_back(fallback_location: root_path)
  end
end
