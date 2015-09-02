class InvitationsController < ApplicationController
  layout 'layouts/invitations'

  rescue_from ActiveRecord::RecordInvalid, with: :error
  rescue_from GitHub::Error,               with: :error
  rescue_from GitHub::Forbidden,           with: :error
  rescue_from GitHub::NotFound,            with: :error

  def show; end

  private

  def error(exception)
    flash[:error] = exception.message.present? ? exception.message : 'Uh oh, an error has occured.'
    redirect_to :back
  end
end
