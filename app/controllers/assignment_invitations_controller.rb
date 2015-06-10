class AssignmentInvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination,    only: [:show]

  def show
    @invitation = AssignmentInvitation.find_by_key!(params[:id])

    if @invitation.redeem(current_user)
      render :success, layout: false, status: 200
    else
      render :failed,  layout: false, status: 503
    end
  end

  private

  def authenticate_with_pre_login_destination
    unless logged_in?
      session[:pre_login_destination] = "#{request.base_url}#{request.path}"
      redirect_to login_path
    end
  end
end
