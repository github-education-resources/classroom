# frozen_string_literal: true

module Errors
  extend ActiveSupport::Concern

  class NotAuthorized < StandardError; end

  def flash_and_redirect_back_with_message(exception)
    flash[:error] = exception.message

    if flash[:error].blank?
      case exception
      when NotAuthorized
        flash[:error] = 'You are not authorized to perform this action'
      when GitHub::Error, GitHub::Forbidden, GitHub::NotFound
        flash[:error] = 'Uh oh, an error has occurred.'
      end
    end

    redirect_back(fallback_location: root_path)
  end

  def render_404(exception)
    case exception
    when ActionController::RoutingError
      render file: Rails.root.join('public', '404.html'), layout: false, status: :not_found
    when ActiveRecord::RecordNotFound
      render file: Rails.root.join('public', 'invalid_link_error.html'), layout: false, status: :not_found
    end
  end
end
