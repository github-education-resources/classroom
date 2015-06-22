class GroupAssignmentInvitationsController < ApplicationController
  before_action :authenticate_with_pre_login_destination, only: [:show]
  before_action :set_invitation

  layout 'layouts/invitations'

  def show
    @grouping = @invitation.group_assignment.grouping
    @groups   = @grouping.groups
  end

  def accept_invitation
    respond_to do |format|
      if @invitation.redeemed?(current_user)
        format.json { render :success, status: :created }
      else
        format.json { render :failed, status: 503 }
      end
    end
  end

  private

  def authenticate_with_pre_login_destination
    return if logged_in?
    session[:pre_login_destination] = "#{request.base_url}#{request.path}"
    redirect_to login_path
  end

  def set_invitation
    @invitation = GroupAssignmentInvitation.find_by_key!(params[:id])
  end
end
